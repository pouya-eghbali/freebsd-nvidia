Apparently when you search for `freebsd nvidia optimus` this repository is #4 on the results. I've recently made a port to make nvidia optimus work on freebsd, you can check it here: 

https://github.com/pouya-eghbali/freebsd-nvidia-optimus

# freebsd-nvidia
Make Optimus work with freebsd

# original instruction

A rough overview of using NVIDIA Optimus on FreeBSD.
 
Make sure nVIDIA Optimus is enabled in BIOS.
 
Install `x11/virtualgl` and `x11/nvidia-driver-optimus`
 
Now you must configure a `/etc/X11/xorg.conf.nv`. Mine looks a little like this:
 
```
Section "ServerLayout"
    Identifier "Layout0"
    Option "AutoAddDevices" "false"
    Option "AllowEmptyInput" "False"
    InputDevice "fake" "CorePointer"
EndSection

Section "Files"
    ModulePath    "/usr/local/lib/xorg/modules/extensions/.nvidia_optimus"
    ModulePath    "/usr/local/lib/xorg/modules"
EndSection

Section "Device"
    Identifier "Device1"
    Driver "nvidia"
    VendorName "NVIDIA Corporation"
    BusID "PCI:01:00:0"
    Option "NoLogo" "true"
    Option "UseEDID" "false"
    Option "ConnectedMonitor" "DFP"
EndSection

Section "InputDevice"
    Identifier "fake"
    Driver ""
EndSection
```
Modify xmj's turn_off_nvidia.sh replacing all _OFF/DOFF/SDOF and so on to read
ON instead. Execute it. Now `kldload nvidia`
 
We can test this now. Run `X -conf xorg.conf.nv -sharevts -noreset :8` in bg.
Now run `/usr/local/VirtualGL/bin/vglrun -ld /usr/local/lib/.nvidia_optimus/ -d ":8" glxgears`
Did it work? Congratulations!
 
And to turn off nVIDIA, simply end the running X server on the nVIDIA card,
`kldunload nvidia`, and execute turn_off_nvidia.sh


#### turn_on_nvidia.sh ####
```
#!/bin/sh

usage() {
  printf "Usage:\t$0\n"
  printf "\tMust be run as root\n"
}

[ "`whoami`" != "root" ] && usage && exit 1

kldstat -q -n acpi_call.ko
MODULE_LOADED=$?

if [ $MODULE_LOADED != "0" ]; then
  echo "The acpi_call module is not loaded, try running `kldload acpi_call` as root"
  exit 1
fi


if [ -f ~/.gpu_method ]; then
echo "Using previously stored method, as it was previously successful..."
. ~/.gpu_method
else
methods="
\_SB.PCI0.P0P1.VGA._ON
\_SB.PCI0.P0P2.VGA._ON
\_SB_.PCI0.OVGA.ATPX
\_SB_.PCI0.OVGA.XTPX
\_SB.PCI0.P0P3.PEGP._ON
\_SB.PCI0.P0P2.PEGP._ON
\_SB.PCI0.P0P1.PEGP._ON
\_SB.PCI0.MXR0.MXM0._ON
\_SB.PCI0.PEG1.GFX0._ON
\_SB.PCI0.PEG0.GFX0.DON
\_SB.PCI0.PEG1.GFX0.DON
\_SB.PCI0.PEG0.PEGP._ON
\_SB.PCI0.XVR0.Z01I.DGOF
\_SB.PCI0.PEGR.GFX0._ON
\_SB.PCI0.PEG.VID._ON
\_SB.PCI0.PEG0.VID._ON
\_SB.PCI0.P0P2.DGPU._ON
\_SB.PCI0.P0P4.DGPU.DON
\_SB.PCI0.IXVE.IGPU.DGON
\_SB.PCI0.RP00.VGA._PS3
\_SB.PCI0.RP00.VGA.P3MO
\_SB.PCI0.GFX0.DSM._T_0
\_SB.PCI0.LPC.EC.PUBS._ON
\_SB.PCI0.P0P2.NVID._ON
\_SB.PCI0.P0P2.VGA.PX02
\_SB_.PCI0.PEGP.DGFX._ON
\_SB_.PCI0.VGA.PX02
\_SB.PCI0.PEG0.PEGP.SGON
\_SB.PCI0.AGP.VGA.PX02
"
fi

for m in $methods; do
echo -n "Trying $m: "
  /usr/local/sbin/acpi_call -p $m -o i
  result=$?
  case "$result" in
  0)
    echo "Call succeeded!"
    if [ ! -f ~/.gpu_method ];
    then
      echo "Storing $m in ~/.gpu_method for reusal"
      echo "export methods=\"$m\"" > ~/.gpu_method
    fi
    break
    ;;
  *)
    echo "failed, continuing"
  ;;
  esac
done
```

there's also this:

```
% fetch https://people.freebsd.org/~xmj/turn_off_gpu.sh
% make -C /usr/ports/sysutils/acpi_call install clean
% vim turn_off_gpu.sh # read it before executing!
% sh turn_off_gpu.sh # as root user
```
