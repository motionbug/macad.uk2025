packer {
  required_plugins {
    tart = {
      version = ">= 1.17.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

# VM Configuration
variable "vm_name" {
  type        = string
  default     = "this_is_the_base_image_name"
  description = "Name of the virtual machine to create"
}

variable "ipsw_url" {
  type        = string
  default     = "/path/to/macos.ipsw"
  description = "URL or path to the macOS TAHOE IPSW file"
}

# Account Configuration
variable "account_userName" {
  type        = string
  default     = "admin"
  description = "Username for the macOS account"
}

variable "account_password" {
  type        = string
  default     = "admin"
  description = "Password for the macOS account"
}

# MDM Enrollment Configuration
variable "enrollment_type" {
  type        = string
  default     = "profile"
  description = "Enrollment type (profile or link)"
}

variable "jamf_url" {
  type        = string
  default     = "https://instance.jamfcloud.com"
  description = "Jamf Cloud URL"
}

variable "mdm_invitation_id" {
  type        = string
  default     = "invitationidhere"
  description = "MDM enrollment invitation ID"
}

# Feature Toggles
variable "enable_passwordless_sudo" {
  type        = string
  default     = "true"
  description = "Enable passwordless sudo for the account"
}

variable "enable_auto_login" {
  type        = string
  default     = "true"
  description = "Enable automatic login for the account"
}

variable "enable_safari_automation" {
  type        = string
  default     = "true"
  description = "Enable Safari automation support"
}

variable "enable_screenlock_disable" {
  type        = string
  default     = "true"
  description = "Disable screen lock"
}

variable "enable_spotlight_disable" {
  type        = string
  default     = "true"
  description = "Disable Spotlight indexing"
}

variable "enable_clipboard_sharing" {
  type        = string
  default     = "false"
  description = "Enable clipboard sharing via tart guest agent"
}

# Locals
locals {
  uuid = uuidv4()
}

# -------------------------
# Source Definition
# -------------------------

source "tart-cli" "tart" {
  from_ipsw    = var.ipsw_url
  vm_name      = var.vm_name
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 50
  ssh_username = "${var.account_userName}"
  ssh_password = "${var.account_password}"
  ssh_timeout  = "180s"
   boot_command = [
    # hello, hola, bonjour, etc.
    "<wait60s><spacebar>",
    # Language: most of the times we have a list of "English"[1], "English (UK)", etc. with
    # "English" language already selected. If we type "english", it'll cause us to switch
    # to the "English (UK)", which is not what we want. To solve this, we switch to some other
    # language first, e.g. "Italiano" and then switch back to "English". We'll then jump to the
    # first entry in a list of "english"-prefixed items, which will be "English".
    #
    # [1]: should be named "English (US)", but oh well 🤷
    "<wait30s>italiano<esc>english<enter>",
    # Select Your Country or Region
    "<wait60s><click 'Select Your Country or Region'><wait5s>united states<leftShiftOn><tab><leftShiftOff><spacebar>",
    # Transfer Your Data to This Mac
    "<wait10s><tab><tab><tab><spacebar><tab><tab><spacebar>",
    # Written and Spoken Languages
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Accessibility
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Data & Privacy
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Create a Mac Account
    "<wait10s><tab><tab><tab><tab><tab><tab>${var.account_userName}<tab>${var.account_userName}<tab>${var.account_password}<tab>${var.account_password}<tab><tab><spacebar><tab><tab><spacebar>",
    # Enable Voice Over
    "<wait120s><leftAltOn><f5><leftAltOff>",
    # Sign In with Your Apple ID
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar><up><spacebar>",
    # Are you sure you want to skip signing in with an Apple ID?
    "<wait10s><tab><spacebar>",
    # Terms and Conditions
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # I have read and agree to the macOS Software License Agreement
    "<wait10s><tab><spacebar>",
    # Age Range -> Adult
    "<wait10s><tab><tab><tab><spacebar>",
    # Enable Location Services
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Are you sure you don't want to use Location Services?
    "<wait10s><tab><spacebar>",
    # Select Your Time Zone
    "<wait10s><tab><tab><tab>UTC<enter><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Analytics
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Screen Time
    "<wait10s><tab><tab><spacebar>",
    # Siri
    "<wait10s><tab><spacebar><leftShiftOn><tab><leftShiftOff><spacebar>",
    # You Mac is Ready for FileVault
    "<wait10s><leftShiftOn><tab><tab><leftShiftOff><spacebar>",
    # Mac Data Will Not Be Securely Encrypted
    "<wait10s><tab><spacebar>",
    # Choose Your Look
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Update Mac Automatically
    "<wait10s><tab><tab><spacebar>",
    # Welcome to Mac
    "<wait30s><spacebar>",
    # Disable Voice Over
    "<wait10s><leftAltOn><f5><leftAltOff>",
    # Enable Keyboard navigation
    # This is so that we can navigate the System Settings app using the keyboard
    "<wait10s><leftAltOn><spacebar><leftAltOff>Terminal<wait10s><enter>",
    "<wait10s><wait10s>defaults write NSGlobalDomain AppleKeyboardUIMode -int 3<enter>",
    # Now that the installation is done, open "System Settings"
    # On Tahoe opening System Settings through Spotlight is not very reliable, sometimes opens System information
    "<wait10s>open '/System/Applications/System Settings.app'<enter>",
    "<wait120s>",
    # Navigate to "Sharing"
    "<wait10s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Sharing<enter>",
    # Navigate to "Screen Sharing" and enable it
    "<wait10s><tab><tab><tab><tab><tab><spacebar>",
    # Type in the password to allow enabling Screen Sharing
    "<wait10s>admin<enter>",
    # Navigate to "Remote Login" and enable it
    "<wait10s><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><spacebar>",
    # Quit System Settings
    "<wait10s><leftAltOn>q<leftAltOff>",
    # Disable Gatekeeper (1/2)
    "<wait10s>sudo spctl --global-disable<enter>",
    "<wait10s>admin<enter>",
    # Disable Gatekeeper (2/2)
    # On Tahoe opening System Settings through Spotlight is not very reliable, sometimes opens System information
    "<wait10s>open '/System/Applications/System Settings.app'<enter>",
    "<wait10s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Privacy & Security<enter>",
    "<wait10s><leftShiftOn><tab><tab><tab><tab><tab><tab><leftShiftOff>",
    "<wait10s><down><wait1s><down><wait1s><enter>",
    "<wait10s>admin<enter>",
    "<wait10s><leftShiftOn><tab><leftShiftOff><wait1s><spacebar>",
    # Quit System Settings
    "<wait10s><leftAltOn>q<leftAltOff>",
  ]
  
  run_extra_args = [
    "--no-audio"
  ]

  // A (hopefully) temporary workaround for Virtualization.Framework's
  // installation process not fully finishing in a timely manner
  create_grace_time = "30s"

  // Keep the recovery partition, otherwise it's not possible to "softwareupdate"
  recovery_partition = "keep"
}

# -------------------------
# Build Section
# -------------------------
build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      "set -euxo pipefail",

      # Passwordless sudo
      "if [ \"${var.enable_passwordless_sudo}\" = \"true\" ]; then",
      "  echo \"Enabling passwordless sudo for ${var.account_userName}...\"",
      "  echo ${var.account_password} | sudo -S sh -c \"mkdir -p /etc/sudoers.d/; echo '${var.account_userName} ALL=(ALL) NOPASSWD: ALL' | EDITOR=tee visudo /etc/sudoers.d/${var.account_userName}-nopasswd\"",
      "fi",

      # Auto-login
      "if [ \"${var.enable_auto_login}\" = \"true\" ]; then",
      "   curl https://raw.githubusercontent.com/karthikeyan-mac/Virtualization_macOS/refs/heads/main/kcpasswordgen.sh -o /tmp/kcpasswordgen.sh",
      "   encoded_value=\"$(bash /tmp/kcpasswordgen.sh ${var.account_password})\"",
      "   echo \"Enabling passwordless login\"",
      "   echo \"$encoded_value\" | sudo xxd -r - /etc/kcpassword",
      "   echo \"$encoded_value\"",
      "   sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser ${var.account_userName}",
      "fi",

      # Screensaver disable (always on)
      "echo \"Disabling screensaver...\"",
      "sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 0",
      "defaults -currentHost write com.apple.screensaver idleTime 0",

      # Prevent sleep (always on)
      "echo \"Preventing system sleep...\"",
      "sudo systemsetup -setsleep Off 2>/dev/null",

      # Safari automation
      "if [ \"${var.enable_safari_automation}\" = \"true\" ]; then",
      "   echo \"Enabling Safari automation...\"",
      "   /Applications/Safari.app/Contents/MacOS/Safari &",
      "   SAFARI_PID=$!",
      "   disown",
      "   sleep 30",
      "   kill -9 $SAFARI_PID",
      "   sudo safaridriver --enable",
      "fi",

      # Screen lock disable
      "if [ \"${var.enable_screenlock_disable}\" = \"true\" ]; then",
      "   echo \"Disabling screen lock...\"",
      "   sysadminctl -screenLock off -password ${var.account_password}",
      "fi",

      # Spotlight disable
      "if [ \"${var.enable_spotlight_disable}\" = \"true\" ]; then",
      "   echo \"Disabling Spotlight indexing...\"",
      "   sudo mdutil -a -i off",
      "fi",

      # Install Tart guest agent
      "if [ \"${var.enable_clipboard_sharing}\" = \"true\" ]; then",
      "   echo \"Installing tart guest agent to enable Clipboard sharing...\"",
      "   /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
      "    /opt/homebrew/bin/brew install cirruslabs/cli/tart-guest-agent",
      "   curl https://raw.githubusercontent.com/cirruslabs/macos-image-templates/refs/heads/main/data/tart-guest-agent.plist -o tart-guest-agent.plist",
      "   sudo mv tart-guest-agent.plist /Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist",
      "   sudo chown -R root:wheel /Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist",
      "fi",
      
      # Set ComputerName
      " computerName=\"VM-TART-$(jot -r 1 1000 9999)\"",
      " sudo scutil --set HostName $computerName",
      " sudo scutil --set LocalHostName $computerName",
      " sudo scutil --set ComputerName $computerName",
    ]
  }

  provisioner "shell" {
    inline = [
      "set -euxo pipefail",
      "if [ \"${var.enrollment_type}\" = \"profile\" ]; then",
      "  cat << 'EOF' > ~/Desktop/mdm_enroll.mobileconfig",
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">",
      "<plist version=\"1.0\">",
      "    <dict>",
      "        <key>PayloadUUID</key>",
      "        <string>${local.uuid}</string>",
      "        <key>PayloadOrganization</key>",
      "        <string>JAMF Software</string>",
      "        <key>PayloadVersion</key>",
      "        <integer>1</integer>",
      "        <key>PayloadIdentifier</key>",
      "        <string>${local.uuid}</string>",
      "        <key>PayloadDescription</key>",
      "        <string>MDM Profile for mobile device management</string>",
      "        <key>PayloadType</key>",
      "        <string>Profile Service</string>",
      "        <key>PayloadDisplayName</key>",
      "        <string>MDM Profile</string>",
      "        <key>PayloadContent</key>",
      "        <dict>",
      "            <key>Challenge</key>",
      "            <string>${var.mdm_invitation_id}</string>",
      "            <key>URL</key>",
      "            <string>${var.jamf_url}/enroll/profile</string>",
      "            <key>DeviceAttributes</key>",
      "            <array>",
      "                <string>UDID</string>",
      "                <string>PRODUCT</string>",
      "                <string>SERIAL</string>",
      "                <string>VERSION</string>",
      "                <string>DEVICE_NAME</string>",
      "                <string>COMPROMISED</string>",
      "            </array>",
      "        </dict>",
      "    </dict>",
      "</plist>",
      "EOF",
      "elif [ \"${var.enrollment_type}\" = \"link\" ]; then",
      "cat << 'EOF' > ~/Desktop/Enroll_Your_Mac.webloc",
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      "<plist version=\"1.0\">",
      "<dict>",
      "    <key>URL</key>",
      "    <string>${var.jamf_url}/enroll?invitation=${var.mdm_invitation_id}</string>",
      "</dict>",
      "</plist>",
      "EOF",
      "fi",
    ]
  }
}
