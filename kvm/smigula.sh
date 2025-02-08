#!/usr/bin/env bash

function print_logo() {
    # Using 256-color codes for a single left-to-right gradient
    local C1='\033[38;5;46m'    # Green start
    local C2='\033[38;5;41m'    # Green-blue transition
    local C3='\033[38;5;37m'    # Teal middle
    local C4='\033[38;5;33m'    # Blue transition
    local C5='\033[38;5;27m'    # Blue end
    local C6='\033[38;5;226m'   # Yellow
    local NC='\033[0m'          # No Color

    # The entire logo with characters colored based on their position
    echo -e "${C1}               ${C6}_${NC}             ${C4}_       ${NC}"
    echo -e "${C1} ___ ${C2}_ __ ___ ${C6}(_) ${C3}__ _ _   ${C4}_| | __ ${C5}_ ${NC}"
    echo -e "${C1}/ __| ${C2}'_ \` _ \| ${C3}|/ _\` | ${C4}| | | |/ ${C5}_\` |${NC}"
    echo -e "${C1}\__ \ ${C2}| | | | | ${C3}| (_| | ${C4}|_| | | ${C5}(_| |${NC}"
    echo -e "${C1}|___/_| ${C2}|_| |_|_|${C3}\__, |\__${C4},_|_|\__${C5},_|${NC}"
    echo -e "${C1}                 ${C3}|___/     ${C3}          ${NC}"
    echo
}

function help() {
    print_logo
    echo "Usage: $0 [OPTIONS] <vm-name> <iso-path>"
    echo
    echo "Create a virtual machine using libvirt/KVM with automated installation via kickstart"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -m, --memory MEMORY     Memory size in MB (default: 2048)"
    echo "  -c, --cpus VCPUS        Number of vCPUs (default: 2)"
    echo "  -d, --disk DISK_SIZE    Disk size in GB (default: 20)"
    echo "  -b, --bridge BRIDGE     Network bridge to use (default: bridge0)"
    echo
    echo "Arguments:"
    echo "  vm-name                 Name of the virtual machine"
    echo "  iso-path                Path to the installation ISO file"
    echo
    echo "Example:"
    echo "  $0 -m 4096 -c 4 -d 40 my-vm /path/to/os.iso"
    echo
    echo "Note: A kickstart.cfg file must be present in the current directory"
}

function parse_args() {
    local MEMORY=2048
    local VCPUS=2
    local DISK_SIZE=20
    local BRIDGE="bridge0"
    local VM_NAME=""
    local ISO_PATH=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                help
                exit 0
                ;;
            -m|--memory)
                MEMORY="$2"
                shift 2
                ;;
            -c|--cpus)
                VCPUS="$2"
                shift 2
                ;;
            -d|--disk)
                DISK_SIZE="$2"
                shift 2
                ;;
            -b|--bridge)
                BRIDGE="$2"
                shift 2
                ;;
            -*)
                echo "Error: Unknown option $1"
                help
                exit 1
                ;;
            *)
                if [ -z "$VM_NAME" ]; then
                    VM_NAME="$1"
                elif [ -z "$ISO_PATH" ]; then
                    ISO_PATH="$1"
                else
                    echo "Error: Unexpected argument $1"
                    help
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Check required positional arguments
    if [ -z "$VM_NAME" ] || [ -z "$ISO_PATH" ]; then
        echo "Error: VM name and ISO path are required"
        help
        exit 1
    fi

    # Return values in an array
    echo "$VM_NAME" "$ISO_PATH" "$MEMORY" "$VCPUS" "$DISK_SIZE" "$BRIDGE"
}

function preflight_check() {
    local required_packages=("qemu-kvm" "libvirt-daemon-system" "libvirt-clients" "bridge-utils" "virt-manager")
    local required_groups=("libvirt" "libvirt-qemu" "kvm")
    local missing_packages=()
    local missing_groups=()
    local current_user=$(whoami)
    local exit_status=0

    echo "Running preflight checks..."
    echo "Checking for required packages..."

    # Check for package manager
    if command -v pacman >/dev/null 2>&1; then
        pkg_manager="pacman"
    elif command -v apt-get >/dev/null 2>&1; then
        pkg_manager="apt"
    elif command -v dnf >/dev/null 2>&1; then
        pkg_manager="dnf"
    elif command -v yum >/dev/null 2>&1; then
        pkg_manager="yum"
    else
        echo "Error: Unable to determine package manager. Supported: pacman, apt, dnf, yum"
        return 1
    fi

    # Check for required packages
    for package in "${required_packages[@]}"; do
        if [ "$pkg_manager" = "apt" ]; then
            if ! dpkg -l | grep -q "^ii.*$package"; then
                missing_packages+=("$package")
            fi
        elif [ "$pkg_manager" = "pacman" ]; then
            if ! pacman -Q "$package" >/dev/null 2>&1; then
                missing_packages+=("$package")
            fi
        else  # dnf or yum
            if ! rpm -q "$package" >/dev/null 2>&1; then
                missing_packages+=("$package")
            fi
        fi
    done

    # Check for required groups
    for group in "${required_groups[@]}"; do
        if ! getent group "$group" >/dev/null 2>&1; then
            echo "Warning: Required group '$group' does not exist"
            missing_groups+=("$group")
            exit_status=1
        elif ! groups "$current_user" | grep -q "\b$group\b"; then
            echo "Warning: Current user '$current_user' is not in required group '$group'"
            exit_status=1
        fi
    done

    # Print results
    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo "Missing required packages: ${missing_packages[*]}"
        echo "Install them using:"
        case $pkg_manager in
            "apt")
                echo "sudo apt-get install ${missing_packages[*]}"
                ;;
            "dnf"|"yum")
                echo "sudo $pkg_manager install ${missing_packages[*]}"
                ;;
            "pacman")
                echo "sudo pacman -S ${missing_packages[*]}"
                ;;
        esac
        exit_status=1
    else
        echo "All required packages are installed."
    fi

    if [ ${#missing_groups[@]} -gt 0 ]; then
        echo "Missing required groups: ${missing_groups[*]}"
    fi

    # Check KVM virtualization support
    if ! grep -q -E 'vmx|svm' /proc/cpuinfo; then
        echo "Warning: CPU virtualization extensions not detected"
        exit_status=1
    fi

    if [ $exit_status -eq 0 ]; then
        echo "All preflight checks passed successfully!"
        return 0
    else
        echo "Some preflight checks failed. Please address the issues above."
        return $exit_status
    fi
}

function create_vm() {
    local VM_NAME=$1
    local ISO_PATH=$2
    local MEMORY=${3:-2048}     # Default to 2GB if not specified
    local VCPUS=${4:-2}         # Default to 2 vCPUs if not specified
    local DISK_SIZE=${5:-20}    # Default to 20GB if not specified
    local BRIDGE=${6:-bridge0}  # Default to bridge0 if not specified 
    
    # Verify kickstart file exists in current directory
    if [ ! -f "./kickstart.cfg" ]; then
        echo "Error: kickstart.cfg not found in current directory"
        return 1
    fi
    
    # Verify ISO file exists
    if [ ! -f "$ISO_PATH" ]; then
        echo "Error: ISO file not found at $ISO_PATH"
        return 1
    fi
    
    echo "Creating VM with following specifications:"
    echo "Name: $VM_NAME"
    echo "ISO: $ISO_PATH"
    echo "Memory: $MEMORY MB"
    echo "vCPUs: $VCPUS"
    echo "Disk Size: $DISK_SIZE GB"
    echo "Using kickstart file: ./kickstart.cfg"
    
    virt-install \
        --name="$VM_NAME" \
        --memory="$MEMORY" \
        --vcpus="$VCPUS" \
        --disk size="$DISK_SIZE" \
        --location="$ISO_PATH" \
        --initrd-inject="./kickstart.cfg" \
        --extra-args="ks=file:/kickstart.cfg console=tty0 console=ttyS0,115200n8" \
        --os-variant="auto" \
        --network bridge=virbr0 \
        --graphics none \
        --noautoconsole \
        --ionmu "model=intel,driver.aw_bits=48"
        
    if [ $? -eq 0 ]; then
        echo "VM creation initiated successfully"
        echo "Monitor progress with: virsh console $VM_NAME"
        return 0
    else
        echo "Error: VM creation failed"
        return 1
    fi
}

function main() {
    print_logo

    # Parse the arguments first
    local args=($(parse_args "$@"))
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # Run preflight checks next
    preflight_check
    local check_status=$?
    
    if [ $check_status -ne 0 ]; then
        echo "Error: Preflight checks failed with status $check_status. Please resolve the issues before creating a VM."
        exit $check_status
    fi

    # If preflight checks pass, proceed with VM creation
    if ! create_vm "${args[@]}"; then
        echo "Error: VM creation failed."
        exit 1
    fi
}

# Show help if requested or no arguments
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    help
    exit 0
fi

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
elif [[ "${BASH_SOURCE[0]}" == "${BASH_SOURCE}" ]]; then
    echo "Currently this script can only be executed directly and not sourced."
    exit 1
fi