import base64

# base64でエンコードされたデータ（この例では省略されています）
encoded_data = "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"

# base64デコード
decoded_data = base64.b64decode(encoded_data)

# PNGファイルとして保存
with open("output.png", "wb") as file:
    file.write(decoded_data)

print("PNGファイルが正常に保存されました。")