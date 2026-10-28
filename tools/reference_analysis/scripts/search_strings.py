import os

# Check MsgSkin.txt
msgskin_path = "D:/GitHub/WLRI/MsgSkin.txt"
if os.path.exists(msgskin_path):
    print("Found MsgSkin.txt")
    with open(msgskin_path, "rb") as f:
        data = f.read()
    # Try big5, gbk, utf-8, latin1
    for enc in ["big5", "gbk", "cp950", "utf-8", "latin1"]:
        try:
            txt = data.decode(enc)
            print(f"Decoded with {enc}, length = {len(txt)}")
            # print first 20 lines
            for line in txt.splitlines()[:30]:
                print("  ", line)
            break
        except Exception:
            pass

# Also search aLogin.exe for strings related to character creation error messages
alogin_path = "D:/GitHub/WLRI/aLogin.exe"
if os.path.exists(alogin_path):
    with open(alogin_path, "rb") as f:
        bin_data = f.read()
    # Search for Chinese or English strings:
    # "Please enter" or "姓名" or "Name"
    keywords = ["name", "Name", "角色", "姓名", "請輸入", "请输入", "未輸入"]
    print("\nSearching aLogin.exe:")
    for enc in ["cp950", "gbk", "ascii"]:
        for kw in keywords:
            try:
                bkw = kw.encode(enc)
                pos = 0
                count = 0
                while count < 3:
                    idx = bin_data.find(bkw, pos)
                    if idx == -1:
                        break
                    # extract surrounding string
                    start = max(0, idx - 10)
                    end = min(len(bin_data), idx + 40)
                    snippet = bin_data[start:end]
                    try:
                        print(f"[{enc}] At {hex(idx)}: {snippet.decode(enc, errors='replace')}")
                    except:
                        pass
                    pos = idx + len(bkw)
                    count += 1
            except Exception:
                pass
