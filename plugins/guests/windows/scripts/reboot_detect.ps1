# Function to check whether machine is currently shutting down
function ShuttingDown {
    [string]$sourceCode = @"
using System;
using System.Runtime.InteropServices;

namespace Vagrant {
    public static class RemoteManager {
        private const int SM_SHUTTINGDOWN = 0x2000;

        [DllImport("User32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetSystemMetrics(int Index);

        public static bool Shutdown() {
            return (0 != GetSystemMetrics(SM_SHUTTINGDOWN));
        }
    }
}
"@
    $type = Add-Type -TypeDefinition $sourceCode -PassThru
    return $type::Shutdown()
}

if (ShuttingDown) {
  exit 1
} else {
  # See if a reboot is scheduled in the future by trying to schedule a reboot
  . shutdown.exe -f -r -t 60

  if ($LASTEXITCODE -eq 1190) {
    # reboot is already pending
    exit 2
  }

  # Remove the pending reboot we just created above
  if ($LASTEXITCODE -eq 0) {
    . shutdown.exe -a
  }
}

# no reboot in progress or scheduled
exit 0
