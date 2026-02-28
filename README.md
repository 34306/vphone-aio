# vphone-aio
1 script run the vphone (iOS 26.1), already jailbroken with full bootstrap installed

Do this step by step:

1. Need brew and python3 installed and then `brew install git-lfs` to install git large files
2. Disable SIP, set amfi_get_out_of_my_way=1
3. Download or clone full this repo (it might take a while, for me 12GB takes me 20 minutes to finish)
4. Run the `vphone-aio.sh` script
5. Make sure your device is free more than 128GB (recommended)
6. Wait until it merge, when merge is done, it will start extract the whole folder (about 15 minutes)
7. You can remove .git and the split file once it's merge done
8. Connect VNC (using RealVNC or Screen sharing): `vnc://127.0.0.1:5901`
9. Enjoy!


# Credits
- [wh1te4ver (Hyungyu Seo)](https://github.com/wh1te4ever) for a super details and writeup: https://github.com/wh1te4ever/super-tart-vphone-writeup

- [Lakr233](https://github.com/Lakr233) for [non-tart repo vphone (vphone-cli)](https://github.com/Lakr233/vphone-cli)
