#!/bin/sh
# =============================================================================
# remove_orphan_kubenet_routes.sh
#
# Removes orphan kubenet routing rules from all route tables associated with
# subnets in a specified VNET. Orphan routes match the naming convention:
#   aks-*******-*******-vmss******
#
# Compatible with: sh, bash, zsh, ksh
# Dependencies:    azure-cli, jq
#
# Usage:
#   ./remove_orphan_kubenet_routes.sh \
#     --resource-group <RG_NAME> \
#     --vnet <VNET_NAME> \
#     [--dry-run] \
#     [--subscription <SUBSCRIPTION_ID>]
#
# Options:
#   --resource-group    Resource group containing the VNET (required)
#   --vnet              Name of the VNET to scan (required)
#   --dry-run           Preview changes without deleting anything (optional)
#   --subscription      Azure subscription ID (optional, uses current if omitted)
# =============================================================================

# Strict mode — POSIX compatible (no -u: unset $@ handling differs across sh)
# set -e

# ── Colour helpers ─────────────────────────────────────────────────────────────
# printf instead of echo -e — echo -e is not portable across sh/ksh
RED=$(printf '\033[0;31m')
YELLOW=$(printf '\033[1;33m')
GREEN=$(printf '\033[0;32m')
CYAN=$(printf '\033[0;36m')
BOLD=$(printf '\033[1m')
RESET=$(printf '\033[0m')

log_info()    { printf "${CYAN}[INFO]${RESET}  %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${RESET}  %s\n" "$*"; }
log_success() { printf "${GREEN}[OK]${RESET}    %s\n" "$*"; }
log_error()   { printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2; }
log_dryrun()  { printf "${YELLOW}[DRY-RUN]${RESET} %s\n" "$*"; }

# ── Usage ──────────────────────────────────────────────────────────────────────
usage() {
  grep '^#' "$0" | sed 's/^# \{0,1\}//' | sed '/^!/d'
  exit 1
}

# ── Argument parsing (plain while/case — works in all POSIX shells) ────────────
RESOURCE_GROUP=""
VNET_NAME=""
DRY_RUN=0
SUBSCRIPTION=""

while [ $# -gt 0 ]; do
  case "$1" in
    --resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    --vnet)
      VNET_NAME="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --subscription)
      SUBSCRIPTION="$2"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      log_error "Unknown argument: $1"
      usage
      ;;
  esac
done

# ── Validate required args ─────────────────────────────────────────────────────
if [ -z "$RESOURCE_GROUP" ]; then
  log_error "--resource-group is required."
  usage
fi
if [ -z "$VNET_NAME" ]; then
  log_error "--vnet is required."
  usage
fi

# ── Dependency check ───────────────────────────────────────────────────────────
for cmd in az jq; do
  if ! command -v "$cmd" > /dev/null 2>&1; then
    log_error "Required tool '$cmd' is not installed or not in PATH."
    exit 1
  fi
done

# ── Subscription context ───────────────────────────────────────────────────────
if [ -n "$SUBSCRIPTION" ]; then
  log_info "Setting subscription: $SUBSCRIPTION"
  az account set --subscription "$SUBSCRIPTION"
fi

CURRENT_SUB=$(az account show --query "name" -o tsv)
log_info "Active subscription : ${BOLD}${CURRENT_SUB}${RESET}"
log_info "Resource group      : ${BOLD}${RESOURCE_GROUP}${RESET}"
log_info "VNET                : ${BOLD}${VNET_NAME}${RESET}"
if [ "$DRY_RUN" = "1" ]; then
  log_warn "DRY-RUN mode — no changes will be made."
fi
printf "\n"

# ── Verify VNET exists ─────────────────────────────────────────────────────────
log_info "Verifying VNET exists..."
if ! az network vnet show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$VNET_NAME" \
      --query "id" -o tsv > /dev/null 2>&1; then
  log_error "VNET '$VNET_NAME' not found in resource group '$RESOURCE_GROUP'."
  exit 1
fi
log_success "VNET found."
printf "\n"

# ── Collect subnets ────────────────────────────────────────────────────────────
log_info "Fetching subnets from VNET '${VNET_NAME}'..."
SUBNETS=$(az network vnet subnet list \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --query "[].{name:name, routeTable:routeTable.id}" \
  -o json)

SUBNET_COUNT=$(printf '%s' "$SUBNETS" | jq 'length')
log_info "Found ${BOLD}${SUBNET_COUNT}${RESET} subnet(s)."
printf "\n"

# ── Orphan route name pattern ──────────────────────────────────────────────────
# Azure CLI returns route names with the address prefix appended via underscores:
# aks-<cluster>-<hash>-vmss<id>____<address>
# The trailing underscore+address part is optional to handle both formats.
# Examples:
#   aks-liftieinfra-14981840-vmss000000____102440024
#   aks-mlinfra-14981840-vmss000000

ORPHAN_PATTERN="^aks-[a-zA-Z0-9]+-[a-zA-Z0-9]+-vmss[a-zA-Z0-9]+(_+[0-9.]+)?$"

# ── Dedup tracker ──────────────────────────────────────────────────────────────
# Newline-separated string of already-processed route table IDs.
# No associative arrays — those are bash 4+ only.
PROCESSED_RT=""

TOTAL_FOUND=0
TOTAL_DELETED=0

# ── Helper: POSIX-safe integer increment ──────────────────────────────────────
# (( n++ )) and let n++ are not portable to plain sh
increment() { printf '%s' "$(( $1 + 1 ))"; }

# ── Main loop — iterate subnets ───────────────────────────────────────────────
i=0
while [ "$i" -lt "$SUBNET_COUNT" ]; do
  SUBNET_NAME=$(printf '%s' "$SUBNETS" | jq -r ".[$i].name")
  RT_ID=$(printf '%s'       "$SUBNETS" | jq -r ".[$i].routeTable // empty")

  printf "${BOLD}── Subnet: %s${RESET}\n" "$SUBNET_NAME"

  # ── Skip subnets with no route table ──────────────────────────────────────
  if [ -z "$RT_ID" ]; then
    log_warn "  No route table attached — skipping."
    printf "\n"
    i=$(increment "$i")
    continue
  fi

  # Derive route table name and its own resource group from the resource ID.
  # ID format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/routeTables/<name>
  RT_NAME=$(printf '%s' "$RT_ID" | awk -F'/' '{print $NF}')
  RT_RG=$(printf '%s'   "$RT_ID" | awk -F'/' '{print $5}')

  log_info "  Route table : ${RT_NAME}  (RG: ${RT_RG})"

  # ── Skip if this route table was already handled ───────────────────────────
  # grep -xF = exact full-line match, no regex special chars
  if printf '%s' "$PROCESSED_RT" | grep -qxF "$RT_ID" 2>/dev/null; then
    log_info "  Already processed this route table — skipping."
    printf "\n"
    i=$(increment "$i")
    continue
  fi

  # Append to processed list
  if [ -z "$PROCESSED_RT" ]; then
    PROCESSED_RT="$RT_ID"
  else
    PROCESSED_RT="${PROCESSED_RT}
${RT_ID}"
  fi

  # ── Fetch routes ───────────────────────────────────────────────────────────
  ROUTES=$(az network route-table route list \
    --resource-group "$RT_RG" \
    --route-table-name "$RT_NAME" \
    --query "[].name" \
    -o json 2>/dev/null) || ROUTES="[]"

  ROUTE_COUNT=$(printf '%s' "$ROUTES" | jq 'length')
  log_info "  Total routes in table: ${ROUTE_COUNT}"

  SUBNET_FOUND=0
  SUBNET_DELETED=0

  # ── Scan each route ────────────────────────────────────────────────────────
  j=0
  while [ "$j" -lt "$ROUTE_COUNT" ]; do
    ROUTE_NAME=$(printf '%s' "$ROUTES" | jq -r ".[$j]")

    if printf '%s' "$ROUTE_NAME" | grep -qE "$ORPHAN_PATTERN"; then
      SUBNET_FOUND=$(increment "$SUBNET_FOUND")
      TOTAL_FOUND=$(increment "$TOTAL_FOUND")

      if [ "$DRY_RUN" = "1" ]; then
        log_dryrun "  Would delete orphan route: ${YELLOW}${ROUTE_NAME}${RESET}"
      else
        log_info "  Deleting orphan route: ${YELLOW}${ROUTE_NAME}${RESET}"
        AZ_ERROR=$(az network route-table route delete \
            --resource-group "$RT_RG" \
            --route-table-name "$RT_NAME" \
            --name "$ROUTE_NAME" 2>&1); AZ_EXIT=$?; true
        if [ "$AZ_EXIT" -eq 0 ]; then
          log_success "  Deleted: ${ROUTE_NAME}"
          SUBNET_DELETED=$(increment "$SUBNET_DELETED")
          TOTAL_DELETED=$(increment "$TOTAL_DELETED")
        else
          log_error "  Failed to delete route: ${ROUTE_NAME}"
          log_error "  Reason: ${AZ_ERROR}"
        fi
      fi
    fi

    j=$(increment "$j")
  done

  # ── Per-subnet summary ─────────────────────────────────────────────────────
  if [ "$SUBNET_FOUND" -eq 0 ]; then
    log_success "  No orphan routes found in this route table."
  elif [ "$DRY_RUN" = "1" ]; then
    log_warn "  ${SUBNET_FOUND} orphan route(s) would be deleted."
  else
    log_success "  Deleted ${SUBNET_DELETED}/${SUBNET_FOUND} orphan route(s)."
  fi

  printf "\n"
  i=$(increment "$i")
done

# ── Final summary ──────────────────────────────────────────────────────────────
printf "${BOLD}════════════════════════════════════════${RESET}\n"
printf "${BOLD}Summary${RESET}\n"
printf "${BOLD}════════════════════════════════════════${RESET}\n"
printf "  Orphan routes found    : ${BOLD}%s${RESET}\n" "$TOTAL_FOUND"

if [ "$DRY_RUN" = "1" ]; then
  printf "  Orphan routes deleted  : ${YELLOW}0 (dry-run)${RESET}\n"
  printf "\n"
  log_warn "Re-run without --dry-run to apply changes."
else
  printf "  Orphan routes deleted  : ${GREEN}%s${RESET}\n" "$TOTAL_DELETED"
  FAILED=$(( TOTAL_FOUND - TOTAL_DELETED ))
  if [ "$FAILED" -gt 0 ]; then
    log_warn "${FAILED} route(s) could not be deleted — check errors above."
  fi
fi
printf "\n"