#!/bin/bash

# ANSI color codes
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

# Default DNS server for A, AAAA, MX, NS, TXT records
default_dns="8.8.8.8"

# Check if dig command is installed
check_dig_command() {
  if ! command -v dig &> /dev/null; then
    echo -e "${RED}Error: Perintah 'dig' tidak ditemukan.${RESET}"
    echo "Instal 'dig' terlebih dahulu sebelum menjalankan skrip ini."
    exit 1
  fi
}

# Function to prompt for domain if not provided
prompt_for_domain() {
  if [ -z "$domain" ]; then
    read -p "Masukkan nama domain: " domain
  fi
}

# Function to display records
display_records() {
  local record_type=$1
  local record_data=$2
  if [ -n "$record_data" ]; then
    echo -e "${CYAN}$record_type record:${RESET}"
    echo "$record_data" | sed 's/^/  /'
  else
    echo -e "${RED}Tidak ada $record_type record untuk $domain${RESET}"
  fi
}

# Function to display PTR records
display_ptr_records() {
  local ip_address=$1
  local ptr_info=$(dig +short -x $ip_address)
  display_records "PTR" "$ptr_info"
}

# Function to display public IP address
display_public_ip() {
  local public_ip=$(curl -s https://api64.ipify.org?format=text)
  echo -e "\n${YELLOW}[Informasi IP Publik]${RESET}"
  echo -e "Public IP Address: ${GREEN}$public_ip${RESET}"
}

# Function to display SSL information
display_ssl_info() {
  local openssl_info=$(openssl s_client -showcerts -connect $domain:443 </dev/null 2>/dev/null | openssl x509 -noout -issuer -dates -subject)
  if [ $? -eq 0 ]; then
    echo -e "\n${CYAN}[Informasi SSL]${RESET}"
    echo "$openssl_info" | sed 's/^/  /'
  else
    echo -e "${RED}Tidak ada informasi SSL yang tersedia atau tidak dapat dibaca untuk $domain pada port 443.${RESET}"
  fi
}

# Function to display DNS information
display_dns_info() {
  local dns_server=$1

  a_record=$(dig +short @$dns_server $domain A)
  display_records "A" "$a_record"

  aaaa_record=$(dig +short @$dns_server $domain AAAA)
  display_records "AAAA (IPv6)" "$aaaa_record"

  mx_record=$(dig +short @$dns_server $domain MX)
  display_records "MX" "$mx_record"

  # Display TXT Record
  txt_record=$(dig +short @$dns_server $domain TXT)
  display_records "TXT" "$txt_record"

  ns_record=$(dig +short @$dns_server $domain NS)
  display_records "NS" "$ns_record"

  if [ -n "$a_record" ]; then
    echo -e "\n${CYAN}[Informasi PTR untuk IPv4]${RESET}"
    display_ptr_records "$a_record"
  fi

  if [ -n "$aaaa_record" ]; then
    echo -e "\n${CYAN}[Informasi PTR untuk IPv6]${RESET}"
    display_ptr_records "$aaaa_record"
  fi
}

# Function to print help
print_help() {
  echo -e "${CYAN}Usage:${RESET} $(basename "$0") ${YELLOW}[-d|--domain domain] [-s|--server dns_server] [-h|--help]${RESET}"
  echo -e "  ${YELLOW}-d, --domain domain${RESET}       Nama domain yang akan diquery"
  echo -e "  ${YELLOW}-s, --server dns_server${RESET}   DNS server kustom untuk A, AAAA, MX, NS, TXT records (opsional)"
  echo -e "  ${YELLOW}-h, --help${RESET}                Menampilkan informasi bantuan"
  echo ""
  echo -e "Contoh Penggunaan:"
  echo -e "  $(basename "$0") ${YELLOW}-d example.com${RESET}"
  echo -e "  $(basename "$0") ${YELLOW}-d example.com -s 1.1.1.1${RESET}"
  exit 0
}

# Main script logic
check_dig_command

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--domain)
      domain=$2
      shift 2
      ;;
    -s|--server)
      dns_server=$2
      shift 2
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo -e "${RED}Pilihan yang tidak valid: $1${RESET}" >&2
      print_help
      exit 1
      ;;
  esac
done

prompt_for_domain

# Set default DNS server if not provided
dns_server=${dns_server:-$default_dns}

echo -e "\n${YELLOW}============================${RESET}"
echo -e "${CYAN}Informasi DNS untuk $domain${RESET}"
echo -e "${YELLOW}DNS Server: $dns_server${RESET}"
echo -e "${YELLOW}============================${RESET}"

# Check if dig command is available before proceeding
if command -v dig &> /dev/null; then
  display_dns_info $dns_server
else
  echo -e "${RED}Error: Perintah 'dig' tidak ditemukan.${RESET}"
  echo "Instal 'dig' terlebih dahulu sebelum menjalankan skrip ini."
fi

# Display public IP address
display_public_ip

echo -e "\n${YELLOW}============================${RESET}"
display_ssl_info

echo -e "\n${YELLOW}============================${RESET}"