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


if [ -f ~/.gpu_on_method ]; then
echo "Using previously stored method, as it was previously successful..."
. ~/.gpu_on_method
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
\_SB.PCI0.XVR0.Z01I.DGON
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
			echo "export methods=\"$m\"" > ~/.gpu_on_method
		fi
		break
		;;
	*)
		echo "failed, continuing"
	;;
	esac
done
