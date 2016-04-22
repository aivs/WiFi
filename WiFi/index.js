/*** WiFi Z-Way HA module *******************************************

Version: 1.0.0
(c) Z-Wave.Me, 2016
-----------------------------------------------------------------------------
Author: Yurkin Vitaliy <aivs@z-wave.me>
Description:
    WiFi Client on Access point mode
******************************************************************************/

// ----------------------------------------------------------------------------
// --- Class definition, inheritance and setup
// ----------------------------------------------------------------------------

function WiFi (id, controller) {
    // Call superconstructor first (AutomationModule)
    WiFi.super_.call(this, id, controller);

    // Create instance variables
    this.checkConnectionInterval = null;
}

inherits(WiFi, AutomationModule);

_module = WiFi;

// ----------------------------------------------------------------------------
// --- Module instance initialized
// ----------------------------------------------------------------------------

WiFi.prototype.init = function (config) {
    WiFi.super_.prototype.init.call(this, config);
    var self = this;

    this.vDev = this.controller.devices.create({
        deviceId: "WiFi_" + this.id,
        defaults: {
            metrics: {
                title: "WiFi",
                text: "Disconnected"
            }          
        },
        overlay: {
            deviceType: "text"
        },
        moduleId: this.id
    });

    // Enable WiFi
    wifiMode = config.wifiMode;

    if (wifiMode == "Client") {
        self.vDev.set("metrics:text", "Client Mode <br>Disconnected, <br>reconnect ...");
        system('/opt/z-way-server/automation/modules/WiFi/bash-scripts/accessPoint.sh stop');
        system('/opt/z-way-server/automation/modules/WiFi/bash-scripts/client.sh connect', config.clientMode_SSID, config.clientMode_password);

        // Check connection every 30 seconds and reconnect if needed
        if (self.checkConnectionInterval) {
            // Timer is set, so we destroy it
            clearInterval(self.checkConnectionInterval);
            self.checkConnectionInterval = null;
        }

        // Client mode check connection
        self.checkConnectionInterval = setInterval(function () {
            var status = system('/opt/z-way-server/automation/modules/WiFi/bash-scripts/client.sh status')[1].replace(/(\r\n|\n|\r)/gm,"");
            if (status == "disconnected") {
                self.vDev.set("metrics:text", "Client Mode <br>Disconnected, <br>reconnect ...");
                system('/opt/z-way-server/automation/modules/WiFi/bash-scripts/client.sh disconnect');
                system('/opt/z-way-server/automation/modules/WiFi/bash-scripts/client.sh connect', config.clientMode_SSID, config.clientMode_password);
            }
            else if (status == "connected"){
                var ip = system('/opt/z-way-server/automation/modules/WiFi/bash-scripts/client.sh ip')[1].replace(/(\r\n|\n|\r)/gm,"");
                self.vDev.set("metrics:text", "Client Mode <br>Connected to " + config.clientMode_SSID + " <br>IP: " + ip);
            }
        }, 30*1000);
    }
    else if (wifiMode == "AccessPoint") {
        system('/opt/z-way-server/automation/modules/WiFi/bash-scripts/client.sh disconnect');

        // Remove interval
        if (self.checkConnectionInterval) {
            // Timer is set, so we destroy it
            clearInterval(self.checkConnectionInterval);
            self.checkConnectionInterval = null;
        }

        system('/opt/z-way-server/automation/modules/WiFi/bash-scripts/accessPoint.sh start', config.accessPointMode_SSID, config.accessPointMode_password);
        var ip = system('/opt/z-way-server/automation/modules/WiFi/bash-scripts/client.sh ip')[1].replace(/(\r\n|\n|\r)/gm,"");
        self.vDev.set("metrics:text", "Access Point "+config.accessPointMode_SSID+ " <br>IP: " + ip);
    };



};

WiFi.prototype.stop = function () {
    WiFi.super_.prototype.stop.call(this);

    // Remove interval
    if (this.checkConnectionInterval){
        clearInterval(this.checkConnectionInterval);
    }

    // Disable WiFi
    if (wifiMode == "Client") {
        system('/opt/z-way-server/automation/modules/WiFi/bash-scripts/client.sh disconnect');
    }
    else if (wifiMode == "AccessPoint") {
        system('/opt/z-way-server/automation/modules/WiFi/bash-scripts/accessPoint.sh stop');
    };
};

// ----------------------------------------------------------------------------
// --- Module methods
// ----------------------------------------------------------------------------
