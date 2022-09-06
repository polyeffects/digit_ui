import module_info
import qrcode


for effect_type, v in module_info.effect_prototypes_models_all.items():
    if "manual_url" in v:
        qr = qrcode.QRCode(
            version=5,
            error_correction=qrcode.constants.ERROR_CORRECT_Q,
            box_size=10,
            border=4,
        )
        qr.add_data(v["manual_url"])
        qr.make(fit=False)
        img = qr.make_image(fill_color="black", back_color="white")
        img.save("icons/digit/qr_codes/manual_"+effect_type+".png")
    if "video_url" in v:
        qr = qrcode.QRCode(
            version=5,
            error_correction=qrcode.constants.ERROR_CORRECT_Q,
            box_size=10,
            border=4,
        )
        qr.add_data(v["video_url"])
        qr.make(fit=False)
        img = qr.make_image(fill_color="black", back_color="white")
        img.save("icons/digit/qr_codes/video_"+effect_type+".png")
