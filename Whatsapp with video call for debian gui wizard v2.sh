#!/bin/bash
# ----------------------------------------------------------------------
# Graphical Waydroid & WhatsApp Installer for Debian/Kali (2026)
# Requires 'zenity' and 'ufw' packages installed first.
# ----------------------------------------------------------------------

# --- USER VARIABLES ---
# Update this with your actual Kali Linux username:
USER_NAME="boq"
DOWNLOADS_PATH="/home/${USER_NAME}/Downloads"

# Function to handle errors and exit gracefully from the GUI
handle_error() {
    zenity --error --title="Error Occurred" --text="$1"
    exit 1
}

# --- Core Functions ---

install_waydroid_gui() {
    (
    echo "10"; echo "# Installing dependencies and adding Waydroid repository..."
    sudo apt update && sudo apt install curl ca-certificates gnupg lsb-release ufw sqlite3 -y || handle_error "Failed to install prerequisites."
    curl -sSL https://repo.waydro.id -o wd.sh
    sudo bash wd.sh bookworm || handle_error "Failed to add Waydroid repository."
    echo "40"; echo "# Installing Waydroid and Weston..."
    sudo apt update
    sudo apt install waydroid weston -y || handle_error "Failed to install waydroid/weston."
    echo "70"; echo "# Initializing Waydroid images (GAPPS included)..."
    sudo waydroid init -s GAPPS || handle_error "Failed to initialize Waydroid images."
    echo "90"; echo "# Enabling waydroid-container service..."
    sudo systemctl enable --now waydroid-container || handle_error "Failed to enable service."
    echo "100"; echo "# Installation complete!"
    ) | zenity --progress --title="Installation Progress" --auto-close --percentage=0 --no-cancel
    
    zenity --info --title="Installation Complete" --text="Installation finished successfully.\n\nIMPORTANT: You must log out and select 'GNOME on Wayland' at the login screen before launching Waydroid."
}

configure_whatsapp_gui() {
    # Check if waydroid is running first
    if ! pgrep waydroid-container > /dev/null; then
        zenity --warning --text="Waydroid container service is not running. Starting it now."
        sudo systemctl start waydroid-container
    fi

    (
    echo "10"; echo "# Granting Video/Audio permissions for WhatsApp..."
    sudo waydroid shell pm grant com.whatsapp android.permission.CAMERA
    sudo waydroid shell pm grant com.whatsapp android.permission.RECORD_AUDIO
    echo "30"; echo "# Bypassing cellular network check..."
    waydroid prop set persist.waydroid.fake_wifi com.whatsapp
    echo "60"; echo "# Setting Tablet Mode (for QR code visibility)..."
    sudo waydroid shell wm size 1280x800 && sudo waydroid shell wm density 120
    echo "90"; echo "# Restarting Waydroid session..."
    waydroid session stop && waydroid session start &
    echo "100"; echo "# Configuration complete!"
    ) | zenity --progress --title="WhatsApp Configuration" --auto-close --percentage=0 --no-cancel

    zenity --info --title="WhatsApp Ready" --text="WhatsApp is configured for video calls and QR login mode.\n\nLaunch WhatsApp from your app menu.\nUse: 3-dots -> Link as companion device -> Scan QR code."
}

fix_play_protect_gui() {
    CHOICE=$(zenity --list --title="Play Protect Fix Method" --column="Choose a method" --height=200 \
        "1. Online Google Registration (Easiest)" \
        "2. Offline Device Spoofing (Technical)")

    case $CHOICE in
        "1. Online Google Registration (Easiest)")
            ANDROID_ID=$(sudo waydroid shell -- sh -c 'sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = \"android_id\";"' | cut -d'|' -f2)
            zenity --info --title="Your Android ID" --text="Your ID is: $ANDROID_ID\n\nClick OK to open the Google Registration page in your browser. Paste this ID there." --no-wrap
            xdg-open "www.google.com"
            zenity --question --text="Did you successfully register the ID online and clear Play Store cache within Waydroid settings?" || exit
            ;;
        "2. Offline Device Spoofing (Technical)")
            sudo systemctl stop waydroid-container
            echo "ro.product.brand = google
ro.product.manufacturer = Google
ro.product.model = Pixel 5
ro.product.name = GM1917
ro.product.device = GM1917
ro.build.fingerprint = google/GM1917/GM1917:11/RKQ1.200826.002/200826.002:user/release-keys" | sudo tee -a /var/lib/waydroid/waydroid.cfg
            sudo waydroid upgrade -o
            sudo systemctl start waydroid-container
            zenity --info --text="Device spoofed. Clear Play Store cache within Waydroid settings if the error persists."
            ;;
        *) exit ;;
    esac
}

nuke_it_gui() {
    zenity --question --text="DANGER: This removes ALL Waydroid data, WhatsApp chats, configs, and repos. Are you sure?" --no-wrap || exit

    (
    echo "10"; echo "# Stopping services..."
    sudo systemctl stop waydroid-container
    waydroid session stop
    echo "30"; echo "# Purging software..."
    sudo apt purge waydroid weston -y
    sudo apt autoremove -y
    echo "60"; echo "# Deleting data directories (Wiping all Android data)..."
    sudo rm -rf /var/lib/waydroid ~/.local/share/waydroid ~/.share/waydroid ~/waydroid
    echo "80"; echo "# Removing repositories and fixing apt keys..."
    sudo rm /etc/apt/sources.list.d/waydroid.list
    sudo rm /usr/share/keyrings/waydroid.gpg
    sudo wget archive.kali.org -O /usr/share/keyrings/kali-archive-keyring.gpg
    sudo dpkg --remove-architecture i386
    sudo apt update
    echo "100"; echo "# Cleanup complete! Go back to the 'Install Waydroid' option to start fresh."
    ) | zenity --progress --title="System Cleanup" --auto-close --percentage=0 --no-cancel
}


# --- Main Menu (Graphical) ---

while true; do
    CHOICE=$(zenity --list --title="Waydroid/WhatsApp Wizard 2026 (boq@Cornholio)" --column="Select an Action" --height=400 --width=550 \
        "1. Install/Setup Waydroid (Fresh Install)" \
        "2. Configure WhatsApp (Fix QR Code/Video Calls)" \
        "3. Fix Play Protect Certification Error (Stop Beeping)" \
        "4. Launch Waydroid UI" \
        "5. I F*&^ed Up (Full Cleanup/Nuke)" \
        "6. Exit Wizard")

    case $CHOICE in
        "1. Install/Setup Waydroid (Fresh Install)") install_waydroid_gui ;;
        "2. Configure WhatsApp (Fix QR Code/Video Calls)") configure_whatsapp_gui ;;
        "3. Fix Play Protect Certification Error (Stop Beeping)") fix_play_protect_gui ;;
        "4. Launch Waydroid UI") waydroid session start & sleep 3 && waydroid show-full-ui & ;;
        "5. I F*&^ed Up (Full Cleanup/Nuke)") nuke_it_gui ;;
        "6. Exit Wizard") exit 0 ;;
        *) break ;;
    esac
done
