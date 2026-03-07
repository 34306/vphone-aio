# vphone-aio
1 script run the vphone (iOS 26.1), already jailbroken with full bootstrap installed

Do this step by step:

1. Install prerequisites:
   ```bash
   brew install git-lfs wget zstd libimobiledevice
   ```
2. Disable SIP, set `amfi_get_out_of_my_way=1`
3. Download or clone this repo (it might take a while, for me 12GB takes me 20 minutes to finish)
4. If any split parts are missing, the script will auto-download them. You can also manually download them:
   ```bash
   for p in aa ab ac ad ae af ag; do
     wget -O "vphone-cli.tar.zst.part_${p}" \
       "https://github.com/34306/vphone-aio/raw/refs/heads/main/vphone-cli.tar.zst.part_${p}?download="
   done
   ```
5. Run the `vphone-aio.sh` script
6. Make sure your device has more than 128GB free (recommended)
7. Wait until it merges. When done, it will extract the whole folder (about 15 minutes)
8. You can remove `.git` and the split files once the merge is done
9. Connect VNC (using RealVNC or Screen Sharing): `vnc://127.0.0.1:5901`
10. Enjoy!

### Experimental VNC mode (faster input / hotkeys)

If default VNC feels laggy, enable the experimental Virtualization.framework VNC path:

```bash
VPHONE_VNC_EXPERIMENTAL=1 ./vphone-aio.sh
```

When enabled, startup logs will print VNC URL/password.
Default values in experimental mode:
- Port: `5901`
- Password: `alpine`

You can override defaults:

```bash
VPHONE_VNC_EXPERIMENTAL=1 \
VPHONE_VNC_PORT=5901 \
VPHONE_VNC_PASSWORD=alpine \
./vphone-aio.sh
```

Example output:

```text
[vphone] VNC password : alpine
[vphone] VNC URL      : vnc://:alpine@127.0.0.1:5901
```

## SHA-256 Checksums

To verify your downloaded files are not corrupted:

```
3c966247deae3fff51a640f6204e0fafc14fd5c76353ba8f28f20f7d1d29e693  vphone-cli.tar.zst.part_aa
c7d11bbbe32dda2b337933c736171cc94faab2c7465e75391fa49029f3b6f1b1  vphone-cli.tar.zst.part_ab
f422949080e7f141f32f35f8ea20c1fedffc2b97eadf0390645114feef6bb1aa  vphone-cli.tar.zst.part_ac
f3acfa47145207b8962ba4d20fb83eb4646934cca768906e65609d7fdde564e7  vphone-cli.tar.zst.part_ad
efdca69df80386b0aa7af8ac260d9ac576ed1f258429fd4ac21b5bbb87cd78fe  vphone-cli.tar.zst.part_ae
4628852da12949361d3ea6efcf8af1532eb52194cc43a4ab4993024267947587  vphone-cli.tar.zst.part_af
8bd1551511eb016325918c2d93519829be04feb54727612e74c32e4299670a88  vphone-cli.tar.zst.part_ag
```

You can verify manually with:
```bash
shasum -a 256 vphone-cli.tar.zst.part_a*
```

# Preview
![](preview.png)

# Credits
- [wh1te4ver (Hyungyu Seo)](https://github.com/wh1te4ever) for a super details and writeup: https://github.com/wh1te4ever/super-tart-vphone-writeup

- [Lakr233](https://github.com/Lakr233) for [non-tart repo vphone (vphone-cli)](https://github.com/Lakr233/vphone-cli)
