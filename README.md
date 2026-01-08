[README.md](https://github.com/user-attachments/files/24487153/README.md)
# Waydroid & WhatsApp Graphical Wizard (Kali/Debian 2026)

This wizard provides a guided, graphical interface (GUI) to install, configure, and troubleshoot Waydroid and WhatsApp on Kali Linux or Debian-based systems. It handles common issues like Play Protect errors, networking problems, and ensures video calling is enabled.

---

## Prerequisites

Before running the wizard script, you must install two packages: `zenity` (for the GUI pop-ups) and `ufw` (for firewall configuration).

Open your terminal and run:
```bash
sudo apt update && sudo apt install zenity ufw -y
