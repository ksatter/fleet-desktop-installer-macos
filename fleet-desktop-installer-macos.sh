#!/bin/sh

# Path to Fleet Agent plist
fleetagentplist="/Library/LaunchDaemons/com.fleetdm.orbit.plist"
# Path to Fleet Agent reloader script
fleetreloadscript="/private/tmp/fleetreloader.sh"
# Path to Fleet Agent reloader plist
fleetreloaddaemon="/private/tmp/com.fleetdm.reload.plist"

# Check if Fleet Agent is installed
if [ ! -f "$fleetagentplist" ]; then
    echo "Fleet Agent is not installed."
    exit 1
else
    echo "Fleet Agent is installed. Continuing..."
fi

# Add Orbit Desktop Channel to Fleet Agent plist
/usr/bin/plutil -insert EnvironmentVariables.ORBIT_DESKTOP_CHANNEL -string "stable" /Library/LaunchDaemons/com.fleetdm.orbit.plist

# Enable Fleet Destop via Fleet Agent plist
/usr/bin/plutil -insert EnvironmentVariables.ORBIT_FLEET_DESKTOP -string "true" /Library/LaunchDaemons/com.fleetdm.orbit.plist

# Create the Fleet Reloader Script
/bin/cat << 'EOF' > "$fleetreloadscript"
#!/bin/sh
/bin/launchctl bootout system /Library/LaunchDaemons/com.fleetdm.orbit.plist
/bin/launchctl bootstrap system /Library/LaunchDaemons/com.fleetdm.orbit.plist
EOF

# Make script executable
/bin/chmod 755 "$fleetreloadscript"

# Change ownership of script (is this needed?)
/usr/sbin/chown root:admin "$fleetreloadscript"

# Create the Fleet Agent Reloader daemon
/bin/cat << 'EOF' > "$fleetreloaddaemon"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.fleetdm.reload</string>
        <key>ProgramArguments</key>
        <array>
            <string>/bin/sh</string>
            <string>/private/tmp/fleetreloader.sh</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>AbandonProcessGroup</key>
        <true/>
        <key>StandardErrorPath</key>
        <string>/dev/null</string>
        <key>StandardOutPath</key>
        <string>/dev/null</string>
    </dict>
</plist>
EOF

# Make plist executable
/bin/chmod 755 "$fleetreloaddaemon"

# Change ownership of plist (is this needed?)
/usr/sbin/chown root:admin "$fleetreloaddaemon"

# Load Fleet Agent Reload plist and wait 5 seconds
/bin/launchctl bootstrap system "$fleetreloaddaemon"; /bin/sleep 5

# Unload Fleet Agent Reload daemon
/bin/launchctl bootout system "$fleetreloaddaemon"

exit 0