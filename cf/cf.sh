#!/bin/bash
export LANG=en_US.UTF-8

# 增强的架构检测
detect_arch() {
    case "$(uname -m)" in
        x86_64|x64|amd64) echo "amd64" ;;
        i386|i686) echo "386" ;;
        arm64|armv8|armv8l|aarch64|iPhone*) echo "arm64" ;;  # 兼容所有iPhone型号
        armv7l) echo "arm" ;;
        mips64le) echo "mips64le" ;;
        mips64) echo "mips64" ;;
        mips|mipsle) echo "mipsle" ;;
        *) echo "unsupported" ;;
    esac
}

cpu=$(detect_arch)
if [ "$cpu" = "unsupported" ]; then
    echo "当前架构为$(uname -m)，暂不支持"
    exit 1
fi

# 改进的网络检测函数
check_network() {
    # 使用更可靠的IPv6检测方法
    if ping6 -c 1 2400:3200::1 &> /dev/null; then
        echo "当前网络支持IPV4+IPV6"
        return 0
    else
        echo "当前网络仅支持IPV4"
        return 1
    fi
}

result() {
    local ip=$1
    [ ! -f "$ip.csv" ] && return 1
    
    # 使用更精确的机场代码匹配
    awk -F ',' '$2 ~ /(BGI|YCC|YVR|YWG|YHZ|YOW|YYZ|YUL|YXE|STI|SDQ|GUA|KIN|GDL|MEX|QRO|SJU|MGM|ANC|PHX|LAX|SMF|SAN|SFO|SJC|DEN|JAX|MIA|TLH|TPA|ATL|HNL|ORD|IND|BGR|BOS|DTW|MSP|MCI|STL|OMA|LAS|EWR|ABQ|BUF|CLT|RDU|CLE|CMH|OKC|PDX|PHL|PIT|FSD|MEM|BNA|AUS|DFW|IAH|MFE|SAT|SLC|IAD|ORF|RIC|SEA)/ {print $0}' "$ip.csv" | sort -t ',' -k5,5n | head -n 3 > "US-$ip.csv"
    
    awk -F ',' '$2 ~ /(CGP|DAC|JSR|PBH|BWN|PNH|GUM|HKG|AMD|BLR|BBI|IXC|MAA|HYD|CNN|KNU|COK|CCU|BOM|NAG|DEL|PAT|DPS|CGK|JOG|FUK|OKA|KIX|NRT|ALA|NQZ|ICN|VTE|MFM|JHB|KUL|KCH|MLE|ULN|MDL|RGN|KTM|ISB|KHI|LHE|CGY|CEB|MNL|CRK|KJA|SVX|SIN|CMB|KHH|TPE|BKK|CNX|URT|TAS|DAD|HAN|SGN)/ {print $0}' "$ip.csv" | sort -t ',' -k5,5n | head -n 3 > "AS-$ip.csv"
    
    awk -F ',' '$2 ~ /(TIA|VIE|MSQ|BRU|SOF|ZAG|LCA|PRG|CPH|TLL|HEL|BOD|LYS|MRS|CDG|TBS|TXL|DUS|FRA|HAM|MUC|STR|ATH|SKG|BUD|KEF|ORK|DUB|MXP|PMO|FCO|RIX|VNO|LUX|KIV|AMS|SKP|OSL|WAW|LIS|OTP|DME|LED|KLD|BEG|BTS|BCN|MAD|GOT|ARN|GVA|ZRH|IST|ADB|KBP|EDI|LHR|MAN)/ {print $0}' "$ip.csv" | sort -t ',' -k5,5n | head -n 3 > "EU-$ip.csv"
}

# 清理旧文件
cleanup() {
    rm -f 6.csv 4.csv US-*.csv AS-*.csv EU-*.csv
}

# 下载必要文件
download_files() {
    local base_url="https://raw.githubusercontent.com/cantzuo/yg_vless_trojan/refs/heads/main/cf/cf.sh"
    
    # 使用更可靠的下载方式
    if ! encoded_cpu=$(printf '%s' "$cpu" | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')
        curl -L -o cf --connect-timeout 15 --retry 3 "${base_url}/${encoded_cpu}"; then
        echo "无法下载cf工具，请检查网络连接"
        return 1
    fi
    chmod +x cf || { echo "无法设置cf可执行权限"; return 1; }
    
    for file in locations.json ips-v4.txt ips-v6.txt; do
        if ! curl -s -o "$file" "$base_url/$file"; then
            echo "无法下载$file"
            return 1
        fi
    done
    return 0
}

# 显示菜单
show_menu() {
    echo "甬哥Github项目  ：github.com/yonggekkk"
    echo "甬哥Blogger博客 ：ygkkk.blogspot.com"
    echo "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
    echo
    echo "如果github被墙，请先通过代理运行一次，后续只用快捷运行：bash cf.sh"
    echo
    echo "请选择优选类型"
    echo "1、仅IPV4优选"
    echo "2、仅IPV6优选"
    echo "3、IPV4+IPV6优选"
    echo "4、重置配置文件"
    echo "5、退出"
}

# 主程序
main() {
    cleanup
    check_network
    
    show_menu
    read -p "请选择【1-5】:" menu
    
    # 检查并下载必要文件
    if ! download_files; then
        echo "初始化失败，请检查网络连接"
        exit 1
    fi
    
    case "$menu" in
        1)
            echo "开始IPv4优选..."
            ./cf -ips 4 -outfile 4.csv && result 4
            ;;
        2)
            echo "开始IPv6优选..."
            ./cf -ips 6 -outfile 6.csv && result 6
            ;;
        3)
            echo "开始IPv4+IPv6优选..."
            ./cf -ips 4 -outfile 4.csv && result 4
            ./cf -ips 6 -outfile 6.csv && result 6
            ;;
        4)
            rm -rf cf locations.json ips-v4.txt ips-v6.txt 6.csv 4.csv US-*.csv AS-*.csv EU-*.csv
            echo "已重置所有配置文件"
            exit 0
            ;;
        5)
            exit 0
            ;;
        *)
            echo "无效选项!"
            exit 1
            ;;
    esac
    
    # 显示结果
    clear
    for ipv in 4 6; do
        if [ -f "$ipv.csv" ]; then
            echo "IPV${ipv}最佳可用节点如下（取前三名）："
            for region in US AS EU; do
                if [ -f "${region}-${ipv}.csv" ]; then
                    echo "${region} IPV${ipv}优选结果："
                    cat "${region}-${ipv}.csv"
                    echo
                fi
            done
        fi
    done
    
    if [ ! -f "4.csv" ] && [ ! -f "6.csv" ]; then
        echo "运行出错，可能原因："
        echo "1. 网络连接问题"
        echo "2. 缺少依赖工具(awk, sort等)"
        echo "3. 测速工具执行失败"
        echo "请检查后重试"
    fi
}

main
