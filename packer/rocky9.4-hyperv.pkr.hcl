packer {
  required_version = ">= 1.7.0"

  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
    hyperv = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/hyperv"
    }
  }
}

variable "iso_url" {
  type    = string
  default = "https://download.rockylinux.org/pub/rocky/9.4/isos/x86_64/Rocky-9.4-x86_64-minimal.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:ee3ac97fdffab58652421941599902012179c37535aece76824673105169c4a2"
}

variable "ssh_username" {
  type    = string
  default = "packer"
}

variable "ssh_password" {
  type      = string
  default   = "rootpassword"  # Should match root password in ks.cfg
  sensitive = true
}

variable "user_password" {
  type      = string
  default   = "packer"
  sensitive = true
}

variable "user_name" {
  type    = string
  default = "rke2"
}

variable "rke2_password" {
  type      = string
  default   = "Rancher363502"
  sensitive = true
}

variable "external_switch_name" {
  type    = string
  default = "YourExternalSwitchName"
}

locals {
  vm_name = "rocky-linux-9.4"
}

source "qemu" "rocky" {
  iso_url            = var.iso_url
  iso_checksum       = var.iso_checksum
  output_directory   = "output-qemu"
  shutdown_command   = "sudo shutdown -P now"
  ssh_username       = "packer"
  # ssh_password       = "packer"
  # ssh_private_key_file = "/home/mmurphy/.ssh/id_rsa"
  ssh_port             = 22
  ssh_timeout          = "30m"
  # ssh_password       = var.ssh_password
  boot_wait          = "5s"
  format             = "raw"
  headless           = true
  accelerator        = "kvm"
  vm_name            = local.vm_name
  disk_size          = "30G"
  
  # boot_command         = ["<tab><bs><bs><bs><bs><bs>text ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"]
  
  boot_command = [
    "<tab><wait>",
    " inst.text inst.ks=hd:fd0:/ks.cfg<enter>"
  ]
  vnc_bind_address = "127.0.0.1"
  vnc_port_min     = 5900
  vnc_port_max     = 6000

  floppy_files = [
    "http/ks.cfg",
    "vncpass.txt"  # Add this line
  ]
  qemuargs = [
    ["-machine", "accel=kvm"],
    ["-cpu", "host"],
    ["-m", "4096"],
    ["-smp", "2"],
    ["-netdev", "user,id=user.0,hostfwd=tcp::{{ .SSHHostPort }}-:22"],
    ["-device", "virtio-net-pci,netdev=user.0"],
    ["-object", "secret,id=vnc_password,file=/etc/qemu/vncpass.txt"],
    ["-drive", "file=output-qemu/rocky-linux-9.4,if=virtio,cache=writeback,discard=ignore,format=raw"],
    ["-drive", "file=/home/mmurphy/.cache/packer/50c7c8865f6fecec41b10c36bf86b3bd9bdb1eaf.iso,media=cdrom,format=raw"],
    ["-boot", "once=d"],
    ["-name", "rocky-linux-9.4"]
  ]
}

build {
  sources = ["source.qemu.rocky"]

  provisioner "file" {
    source      = "http/ks.cfg"
    destination = "/tmp/ks.cfg"
    # template    = true
  }

  provisioner "shell" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y cloud-init",
      "sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org",
      "sudo dnf install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm -y",
      "sudo dnf --enablerepo=elrepo-kernel install kernel-ml -y",
      "sudo grub2-set-default 0",
      "sudo grub2-mkconfig -o /boot/grub2/grub.cfg",
      "sudo rm -f /etc/ssh/ssh_host_*",
      "sudo cloud-init clean",
      "sudo rm -rf /tmp/* /var/tmp/*",
      "sudo dd if=/dev/zero of=/zerofile bs=1M || echo 'Zeroing completed'",
      "sudo rm -f /zerofile"
    ]
  }
}
