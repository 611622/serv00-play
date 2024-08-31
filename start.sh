#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'
yellow(){
  echo -e "${YELLOW} $1 ${RESET}"
}
green(){
  echo -e "${GREEN} $1 ${RESET}"
}
red(){
  echo -e "${RED} $1 ${RESET}"
}
installpath="$HOME"
art_wrod=$(figlet "serv00-play")
echo "<------------------------------------------------------------------>"
echo -e "${CYAN}${art_wrod}${RESET}"
echo -e "${GREEN} 饭奇骏频道:https://www.youtube.com/@frankiejun8965 ${RESET}"
echo -e "${GREEN} TG交流群:https://t.me/fanyousuiqun ${RESET}"
echo "<------------------------------------------------------------------>"

PS3="请选择(输入0退出): "
install(){
  cd
  if [ -d serv00-play ]; then
    cd "serv00-play"
    git stash
    if git pull; then
      echo "更新完毕"
      return
    fi
  fi

  echo "正在安装..."
  if ! git clone https://github.com/frankiejun/serv00-play.git; then
    echo -e "${RED}安装失败!${RESET}"
    exit 1;
  fi
  echo -e "${YELLOW}安装成功${RESET}"
}

checkvlessAlive(){
  if  ps  aux | grep app.js | grep -v "grep" ; then
    return 0
  else
    return 1
  fi  
}

checkvmessAlive(){
  local c=0
  if ps  aux | grep web.js | grep -v "grep" > /dev/null ; then
    ((c+1))
  fi

  if ps aux | grep cloud | grep -v "grep" > /dev/null ; then
    ((c+1))
  fi  

  if [ $c -eq 2 ]; then
    return 0
  fi

  return 1 # 有一个或多个进程不在运行

}

checkSingboxAlive(){
  local c=0
  if ps  aux | grep serv00sb | grep -v "grep" > /dev/null ; then
    ((c+1))
  fi

  if ps aux | grep cloudflare | grep -v "grep" > /dev/null ; then
    ((c+1))
  fi  

  if [ $c -eq 2 ]; then
    return 0
  fi

  return 1 # 有一个或多个进程不在运行

}

startVless(){
  cd ${installpath}/serv00-play/vless
  
  if checkvlessAlive; then
    echo -e "${RED}vless 已在运行，请勿重复操作!${RESET}"
    exit 1
  fi

  if ! ./start.sh; then
    echo e "${RED}vless启动失败！${RESET}"
    exit 1
  fi

  echo -e "${YELLOW}启动成功!${RESET}"

}

startVmess(){
  cd ${installpath}/serv00-play/vmess
  
  if checkvmessAlive; then
    echo -e "$RED}vmess 已在运行，请勿重复操作!${RESET}"
    exit 1
  else
    chmod 755 ./killvmess.sh
    ./killvmess.sh
  fi

  if ! ./start.sh; then
    echo "vmess启动失败！"
    exit 1
  fi

  echo -e "${YELLOW}启动成功!${RESET}"

}

stopVless(){
  r=$(ps aux | grep app.js | grep -v "grep" | awk '{print $2}' )
  if [ -z "$r" ]; then
    echo "没有运行!"
    return
  else  
    kill -9 $r
  fi
  echo "已停掉vless!"
}

stopVmess(){
  cd ${installpath}/serv00-play/vmess
  if [ -f killvmess.sh ]; then
    chmod 755 ./killvmess.sh
    ./killvmess.sh
  else
    echo "请先安装serv00-play!!!"
    return
  fi
  echo "已停掉vmess!"
}

createVlesConfig(){

      #read -p "请输入UUID:" uuid
      read -p "请输入PORT:" port

      cat > vless.json <<EOF
      {
        "UUID":"$(uuidgen -r)",
        "PORT":$port

      }
EOF
}

configVless(){
  cd ${installpath}/serv00-play/vless
  
  if [ -f "vless.json" ]; then
    echo "配置文件内容:"
     cat vless.json
    read -p "配置文件已存在，是否还要重新配置 (y/n) [y]?" input
    input=${input:-y}
    if [ "$input" != "y" ]; then
      return
    else
     createVlesConfig
    fi
  else
     createVlesConfig
  fi
    echo -e "${YELLOW} vless配置完毕! ${RESET}"
  
}

createVmesConfig(){
   read -p "请输入vmess代理端口:" vmport
  # read -p "请输入uuid:" uuid
   read -p "请输入WSPATH,默认是[serv00]" wspath
   wspath=${wspath:-serv00}

   read -p "请输入ARGO隧道token，如果没有按回车跳过:" token
   read -p "请输入ARGO隧道的域名，如果没有按回车跳过:" domain

  cat > vmess.json <<EOF
  {
     "VMPORT": $vmport,
     "UUID": "$(uuidgen -r)",
     "WSPATH": "$wspath",
     "ARGO_AUTH": "${token:-null}",
     "ARGO_DOMAIN": "${domain:-null}"
  }

EOF
   echo -e "${YELLOW} vmess配置完毕! ${RESET}"
}

configVmess(){
  cd ${installpath}/serv00-play/vmess

  if [ -f ./vmess.json ]; then
    echo "配置文件内容:"
    cat ./vmess.json
    read -p "配置文件已存在，是否还要重新配置 (y/n) [y]?" input
    input=${input:-y}
    if [ "$input" != "y" ]; then
      return
    else
     createVmesConfig
    fi
  else
     createVmesConfig
  fi

}

showVlessInfo(){
  user=$(whoami)
  domain=${user}".serv00.net"
  
  cd ${installpath}/serv00-play/vless
  if [ ! -f vless.json ]; then
    echo -e "${RED} 配置文件不存在，请先行配置! ${RESET}"
    return
  fi
  uuid=$(jq -r ".UUID" vless.json)
  port=$(jq -r ".PORT" vless.json)
  url="vless://${uuid}@${domain}:${port}?encryption=none&security=none&sni=${domain}&allowInsecure=1&type=ws&host=${domain}&path=%2F#serv00-vless"
  echo "v2ray:"
  echo -e "${GREEN}   $url ${RESET}"
}

showVmessInfo(){
  cd ${installpath}/serv00-play/vmess

  if [ ! -f vmess.json ]; then
      echo -e "${RED} 配置文件不存在，请先行配置! ${RESET}"
      return
  fi
  chmod +x ./list.sh && ./list.sh
}


showSingBoxInfo(){
  cd ${installpath}/serv00-play/singbox
  
  if [ ! -f singbox.json ]; then
      red "配置文件不存在，请先行配置!"
      return
  fi
  
  if [ ! -e list ]; then
     red "请先运行sing-box"
  fi
  cat ./list
}

writeWX(){
  has_fd=$(echo "$config_content" | jq 'has("wxsendkey")')
  if [ "$has_fd" == "true" ]; then
     wx_sendkey=$(echo "$config_content" | jq -r ".wxsendkey")
     read -p "已有 WXSENDKEY ($wx_sendkey), 是否修改? [y/n] [n]" input
     input=${input:-n}
    if [ "$input" == "y" ]; then
      read -p "请输入 WXSENDKEY:" wx_sendkey
    fi
    json_content+="  \"wxsendkey\": \"${wx_sendkey}\", \n"
 else
    read -p "请输入 WXSENDKEY:" wx_sendkey
    json_content+="  \"wxsendkey\": \"${wx_sendkey}\", \n"
 fi

}

writeTG(){
  has_fd=$(echo "$config_content" | jq 'has("telegram_token")')
  if [ "$has_fd" == "true" ]; then
    tg_token=$(echo "$config_content" | jq -r ".telegram_token")
    read -p "已有 TELEGRAM_TOKEN ($tg_token), 是否修改? [y/n] [n]" input
    input=${input:-n}
    if [ "$input" == "y" ]; then
       read -p "请输入 TELEGRAM_TOKEN:" tg_token
    fi
    json_content+="  \"telegram_token\": \"${tg_token}\", \n"
  else
    read -p "请输入 TELEGRAM_TOKEN:" tg_token
    json_content+="  \"telegram_token\": \"${tg_token}\", \n"
  fi

  has_fd=$(echo "$config_content" | jq 'has("telegram_userid")')
  if [ "$has_fd" == "true" ]; then
     tg_userid=$(echo "$config_content" | jq -r ".telegram_userid")
     read -p "已有 TELEGRAM_USERID ($tg_userid), 是否修改? [y/n] [n]" input
     input=${input:-n}
     if [ "$input" == "y" ]; then
       read -p "请输入 TELEGRAM_USERID:" tg_userid
     fi
     json_content+="  \"telegram_userid\": \"${tg_userid}\", \n"
  else
    read -p "请输入 TELEGRAM_USERID:" tg_userid
    json_content+="  \"telegram_userid\": \"${tg_userid}\",\n"
    fi
}

chooseSingbox(){
  read -p "保活sing-box中哪个项目: 1.hy2, 2.vmess, 3.all 请选择:" input
  
  if [ "$input" = "1" ]; then
     item+=("hy2")
  elif [ "$input" = "2" ]; then
      item+=("vmess")
  elif [ "$input" = "3" ]; then
  item+=("hy2")
  item+=("vmess")
  else 
      red "无效选择!"
      return 1
 fi

}


createConfigFile(){
   cd ${installpath}/serv00-play/
  
  echo "请选择要保活的项目:"
  echo "1. vless "
  echo "2. sing-box "
  echo "3. 以上皆是"
  echo "4. 以上皆不是(暂停所有保活功能)"
  read -p "请选择:" num
  item=()

  if [ "$num" = "1" ]; then
    item+=("vless")
  elif [ "$num" = "2" ]; then
     if ! chooseSingbox; then
      return 
     fi
  elif [ "$num" = "3" ];then
    item+=("vless")
    chooseSingbox 
  elif [ "$num" = "4" ]; then
    item=()
  else
    echo "无效选择"
    return
  fi

  json_content="{\n"
  json_content+="   \"item\": [\n"
  
  for item in "${item[@]}"; do
      json_content+="      \"$item\","
  done

  # 删除最后一个逗号并换行
  json_content="${json_content%,}\n"
  json_content+="   ],\n"

  if [ "$num" = "4" ]; then
    json_content+="   \"chktime\": \"null\""
    json_content+="}\n"
    printf "$json_content" > ./config.json
    echo -e "${YELLOW} 设置完成! ${RESET} "
    crontab -l | grep -v "keepalive" > mycron
    crontab mycron
    rm mycron
    return
  fi

  read -p "配置保活检查的时间间隔(单位分钟，默认5分钟):" tm
  tm=${tm:-"5"}

  json_content+="   \"chktime\": \"$tm\","

  read -p "是否需要配置消息推送? [y/n] [n]" input
  input=${input:-n}

  if [ "${input}" == "y" ]; then
    json_content+=",\n"

    echo "选择要推送的app:"
    echo "1) Telegram "
    echo "2) 微信 "
    echo "3) 以上皆是"

    read -p "请选择:" sendtype
    
    if [ "$sendtype" == "1" ]; then
      writeTG
   elif [ "$sendtype" == "2" ]; then
      writeWX
   elif [ "$sendtype" == "3" ]; then
      writeTG
      writeWX
   else
    echo "无效选择"
    return
   fi
  else 
    sendtype=${sendtype:-"null"}
 fi
  json_content+="\n \"sendtype\": $sendtype \n"
  json_content+="}\n"
  
  # 使用 printf 生成文件
  printf "$json_content" > ./config.json

  crontab -l | grep -v "keepalive" > mycron
  echo "*/$tm * * * * bash ${installpath}/serv00-play/keepalive.sh > /dev/null 2>&1 " >> mycron
  crontab mycron
  rm mycron
  chmod +x ${installpath}/serv00-play/keepalive.sh
  

  echo -e "${YELLOW} 设置完成! ${RESET} "

}

setConfig(){
  cd ${installpath}/serv00-play/

  if [ -f config.json ]; then
    echo "目前已有配置:"
    config_content=$(cat config.json)
    echo $config_content
    read -p "是否修改? [y/n] [y]" input
    input=${input:-y}
    if [ "$input" != "y" ]; then
      return
    fi
  fi
  createConfigFile
}

make_vmess_config() {
  cat >tempvmess.json <<EOF
  {
      "tag": "vmess-ws-in",
      "type": "vmess",
      "listen": "::",
      "listen_port": $vmport,
      "users": [
      {
        "uuid": "$uuid"
      }
    ],
    "transport": {
      "type": "ws",
      "path": "/$wspath",
      "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
EOF
}

make_hy2_config() {
  cat > temphy2.json <<EOF
   {
       "tag": "hysteria-in",
       "type": "hysteria2",
       "listen": "::",
       "listen_port": $hy2_port,
       "users": [
         {
             "password": "$uuid"
         }
     ],
     "masquerade": "https://www.bing.com",
     "tls": {
         "enabled": true,
         "alpn": [
             "h3"
         ],
         "certificate_path": "cert.pem",
         "key_path": "private.key"
        }
    }
EOF
}

generate_config() {
   comma=""
  if [[ ! -e "private.key" || ! -e "cert.pem" ]]; then
    openssl ecparam -genkey -name prime256v1 -out "private.key"
    openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=www.bing.com"
  fi
  if [ "$type" = "1" ]; then
    make_vmess_config
  elif [ "$type" = "2" ]; then
    make_hy2_config
  else
    make_vmess_config
    make_hy2_config
    comma=","
  fi

  cat >config.json <<EOF
 {
  "log": {
    "disabled": true,
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "google",
        "address": "tls://8.8.8.8",
        "strategy": "ipv4_only",
        "detour": "direct"
      }
    ],
    "rules": [
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "server": "block"
      }
    ],
    "final": "google",
    "strategy": "",
    "disable_cache": false,
    "disable_expire": false
  },
    "inbounds": [
    $([[ "$type" == "1" || "$type" == "3" ]] && cat tempvmess.json)
    $comma
    $([[ "$type" == "2" || "$type" == "3" ]] && cat temphy2.json)
   ],
    "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    },
    {
      "type": "dns",
      "tag": "dns-out"
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      },
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "outbound": "block"
      }
    ],
    "rule_set": [
      {
        "tag": "geosite-category-ads-all",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
        "download_detour": "direct"
      }
    ],
    "final": "direct"
   }
}
EOF
rm -rf tempvmess.json temphy2.json
}


configSingBox(){
  cd ${installpath}/serv00-play/singbox

  if [ -e singbox.json ]; then
    red "目前已有配置如下:"
    cat singbox.json
    read -p "$(echo -e "${RED}继续配置将会覆盖原有配置:[y/n] [n]${RESET}") " input
    input=${input:-n}
    if [ "$input" = "n" ]; then
       return 
    fi
  fi
  echo "选择你要配置的项目:"  
  echo "1. vmess"
  echo "2. hy2 "
  echo "3. all "
  
  read -p "请选择:" type
  type=${type:-"3"}

  if [[ "$type" = "1" ]]; then
   read -p "请输入vmess代理端口(tcp):" vmport
   read -p "请输入WSPATH,默认是[serv00]" wspath
   read -p "请输入ARGO隧道token:" token
   read -p "请输入ARGO隧道的域名:" domain
  elif [[ "$type" == "2" ]]; then
   read -p "请输入hy2代理端口(udp):" hy2_port
  elif [[ "$type" == "3" ]]; then
   read -p "请输入vmess代理端口(tcp):" vmport
   read -p "请输入WSPATH,默认是[serv00]" wspath
   read -p "请输入ARGO隧道token:" token
   read -p "请输入ARGO隧道的域名:" domain
   read -p "请输入hy2代理端口(udp):" hy2_port
 
  else
     red "选择无效!"
     return
  fi
  wspath=${wspath:-serv00}
  uuid=$(uuidgen -r)
   
   cat > singbox.json <<EOF
  {
     "TYPE": $type,
     "VMPORT": ${vmport:-null},
     "HY2PORT": ${hy2_port:-null},
     "UUID": "$uuid",
     "WSPATH": "${wspath}",
     "ARGO_AUTH": "${token:-null}",
     "ARGO_DOMAIN": "${domain:-null}"
  }

EOF

    generate_config
    yellow "vmess配置完毕!"  

}

startSingBox(){

  cd ${installpath}/serv00-play/singbox
  
  
  if [[ ! -e serv00sb ]] || [[ $(file serv00sb) == *"text"* ]]; then
    echo "downloading serv00sb..."
    url="https://gfg.fkjdemo.us.kg/app/serv00/serv00sb?pwd=$password"
    curl -L -sS --max-time 10 -o serv00sb "$url"
    if file serv00sb | grep "text" ; then
        echo "使用密码不正确!!!"
        rm -f serv00sb
        return
    fi
    echo "done!"
  fi

  if checkSingboxAlive; then
    red "sing-box 已在运行，请勿重复操作!"
    exit 1
  else
    chmod 755 ./killsing-box.sh
    ./killsing-box.sh
  fi

  if chmod +x start.sh && ! ./start.sh; then
    red "sing-box启动失败！"
    exit 1
  fi

  yellow "启动成功!"

}


stopSingBox(){

  cd ${installpath}/serv00-play/singbox
  if [ -f killsing-box.sh ]; then
    chmod 755 ./killsing-box.sh
    ./killsing-box.sh
  else
    echo "请先安装serv00-play!!!"
    return
  fi
  echo "已停掉sing-box!"


}

uninstall(){
  read -p "确定卸载吗? [y/n] [n]" input
  input=${input:-n}

  if [ "$input" == "y" ]; then
    stopVless
    stopVmess
    stopSingBox
    cd $HOME
    rm -rf serv00-play
    echo "bye!"
  fi
}


if [ ! -e ${installpath}/serv00-play/singbox/serv00sb ]; then
  read -sp "请输入使用密码:" password
  echo ""
fi
echo "请选择一个选项:"

options=("安装/更新serv00-play项目" "运行vless"  "停止vless"  "配置vless"  "显示vless的节点信息"  "设置保活的项目" "配置sing-box" "运行sing-box" "停止sing-box" "显示sing-box节点信息" "卸载" )

select opt in "${options[@]}"
do
    case $REPLY in
        1)
            install
            ;;
        2)
            read -p "请确认${installpath}/serv00-play/vless/vless.json 已配置完毕 (y/n) [y]?" input
            input=${input:-y}
            if [ "$input" != "y" ]; then
              echo "请先进行配置!!!"
              exit 1
            fi
            startVless
            ;;
        3)
            stopVless
            ;;

        4)
            configVless
            ;;
        5)
            showVlessInfo
            ;;
        6)
           setConfig
           ;;
        7)
          configSingBox
          ;;
        8)
          startSingBox
          ;;
       9)
          stopSingBox
          ;;
       10)
          showSingBoxInfo
          ;;
        11)
           uninstall
           ;;
        0)
            echo "退出"
            break
            ;;
        *)
            echo "无效的选项 "
            ;;
    esac
done
