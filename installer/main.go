package main

import (
	_ "embed"
	"fmt"
	"os"
	"path/filepath"

	"github.com/siderolabs/go-copy/copy"
	"github.com/siderolabs/talos/pkg/machinery/overlay"
	"github.com/siderolabs/talos/pkg/machinery/overlay/adapter"
	"golang.org/x/sys/unix"
)

const (
	dtb           = "rockchip/rk3588s-orangepi5.dtb"
	overlayPrefix = "rockchip/overlay"
)

func main() {
	adapter.Execute(&BoardInstaller{})
}

type BoardInstaller struct{}

type boardExtraOptions struct {
	Sata bool `json:"sata"`
}

func (i *BoardInstaller) GetOptions(extra boardExtraOptions) (overlay.Options, error) {
	kernelArgs := []string{
		"console=tty1",
		"console=ttyS2:1500000",
		"sysctl.kernel.kexec_load_disabled=1",
		"talos.dashboard.disabled=1",
	}

	return overlay.Options{
		Name:       "orangepi-5",
		KernelArgs: kernelArgs,
	}, nil
}

func (i *BoardInstaller) Install(options overlay.InstallOptions[boardExtraOptions]) error {
	var f *os.File

	f, err := os.OpenFile(options.InstallDisk, os.O_RDWR|unix.O_CLOEXEC, 0o666)
	if err != nil {
		return fmt.Errorf("failed to open %s: %w", options.InstallDisk, err)
	}

	defer f.Close() //nolint:errcheck

	err = f.Sync()
	if err != nil {
		return err
	}

	// Copy dtb files
	src := filepath.Join(options.ArtifactsPath, "arm64/dtb", dtb)
	dst := filepath.Join(options.MountPrefix, "/dtb/base", dtb)
	err = CopyFile(src, dst)
	if err != nil {
		return err
	}

	// Skip copying overlay dtb files if sata is not enabled
	if !options.ExtraOptions.Sata {
		return nil
	}

	// Copy overlay dtb files
	src = filepath.Join(options.ArtifactsPath, "arm64/dtb", overlayPrefix, "rockchip-rk3588-sata1.dtbo")
	dst = filepath.Join(options.MountPrefix, "/dtb/overlay", "rockchip-rk3588-sata1.dtbo")
	err = CopyFile(src, dst)
	if err != nil {
		return err
	}

	src = filepath.Join(options.ArtifactsPath, "arm64/dtb", overlayPrefix, "rockchip-rk3588-sata2.dtbo")
	dst = filepath.Join(options.MountPrefix, "/dtb/overlay", "rockchip-rk3588-sata2.dtbo")
	err = CopyFile(src, dst)
	if err != nil {
		return err
	}

	return nil
}

func CopyFile(src, dst string) error {
	err := os.MkdirAll(filepath.Dir(dst), 0o600)
	if err != nil {
		return err
	}

	return copy.File(src, dst)
}
