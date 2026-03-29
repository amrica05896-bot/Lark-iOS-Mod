#!/data/data/com.termux/files/usr/bin/bash

echo ">>> [0] تجهيز البيئة..."

pkg update -y
pkg upgrade -y

pkg install -y openjdk-17 wget curl zipalign apksigner git aapt

# تثبيت apktool
if [ ! -f apktool.jar ]; then
    echo ">>> تحميل apktool..."
    wget https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool -O apktool
    wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar -O apktool.jar
    chmod +x apktool
    mv apktool $PREFIX/bin/
fi

echo ">>> [1] التأكد من وجود APK..."

if [ ! -f "lark_player.apk" ]; then
    echo "❌ حط ملف lark_player.apk هنا وشغل تاني"
    exit 1
fi

echo ">>> [2] فك التطبيق..."
apktool d -f lark_player.apk -o mod_app

echo ">>> [3] إصلاح public.xml لو فيه مشاكل..."
PUB="mod_app/res/values/public.xml"
if [ -f "$PUB" ]; then
    sed -i '/0x00/d' "$PUB"
fi

echo ">>> [4] إنشاء Glass UI..."

mkdir -p mod_app/res/drawable

cat << 'XML' > mod_app/res/drawable/ios_glass_ui.xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">

    <item>
        <shape>
            <gradient
                android:startColor="#66FFFFFF"
                android:endColor="#22FFFFFF"
                android:angle="270"/>
            <corners android:radius="28dp"/>
        </shape>
    </item>

    <item>
        <shape>
            <stroke
                android:width="1dp"
                android:color="#88FFFFFF"/>
            <corners android:radius="28dp"/>
        </shape>
    </item>

</layer-list>
XML

echo ">>> [5] تعديل كل Layouts..."

find mod_app/res -type f -name "*.xml" | while read file; do
    if [[ "$file" == *layout* ]]; then
        
        sed -i 's/android:background="[^"]*"//g' "$file"

        if ! grep -q "ios_glass_ui" "$file"; then
            sed -i '0,/<[a-zA-Z]/s//& android:background="@drawable\/ios_glass_ui" android:alpha="0.93" android:elevation="12dp"/' "$file"
        fi

    fi
done

echo ">>> [6] تعديل Manifest (إزالة splits)..."

MAN="mod_app/AndroidManifest.xml"
if [ -f "$MAN" ]; then
    sed -i '/splits/d' "$MAN"
    sed -i '/com.android.vending.splits/d' "$MAN"
fi

echo ">>> [7] تحسين styles..."

STYLES="mod_app/res/values/styles.xml"
if [ -f "$STYLES" ]; then
    sed -i 's/<item name="android:windowIsTranslucent">false<\/item>/<item name="android:windowIsTranslucent">true<\/item>/g' "$STYLES"
fi

echo ">>> [8] بناء APK..."

apktool b mod_app -o unsigned.apk

if [ ! -f unsigned.apk ]; then
    echo "❌ فشل build"
    exit 1
fi

echo ">>> [9] Zipalign..."
zipalign -p 4 unsigned.apk aligned.apk

echo ">>> [10] توقيع APK..."

keytool -genkey -v -keystore key.keystore -storepass 123456 -alias key -keypass 123456 -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Glass,O=Android,C=US"

apksigner sign --ks key.keystore --ks-pass pass:123456 --out final_glass.apk aligned.apk

echo ">>> ✅ خلصنا بنجاح!"
echo "📦 اسم الملف: final_glass.apk"

ls -lh final_glass.apk
