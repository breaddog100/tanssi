#!/bin/bash

# 安装建设者节点
function install_builders_node() {

	sudo apt update
    sudo apt upgrade -y

    # 检查 Docker 是否已安装
    if ! command -v docker &> /dev/null
    then
        echo "安装Docker..."
        sudo apt install  -y ca-certificates curl gnupg lsb-release docker.io
    else
        echo "Docker 已安装。"
    fi
    
    # 下载 Tanssi 应用链程序
	mkdir -p $HOME/appchain-data
	wget -P $HOME/appchain-data https://github.com/moondance-labs/tanssi/releases/latest/download/container-chain-template-frontier-node
	wget -P $HOME/appchain-data https://github.com/moondance-labs/tanssi/releases/latest/download/container-chain-template-simple-node
	wget -P $HOME/appchain-data https://raw.githubusercontent.com/papermoonio/external-files/main/Moonbeam/Moonbase-Alpha/westend-alphanet-raw-specs.json	
	chmod +x $HOME/appchain-data/*
	
	# 用户参数
	read -p "YOUR_APPCHAIN_SPECS_FILE_LOCATION: " YOUR_APPCHAIN_SPECS_FILE_LOCATION
	read -p "INSERT_YOUR_APPCHAIN_BOOTNODE: " INSERT_YOUR_APPCHAIN_BOOTNODE
	read -p "YOUR_APPCHAIN_SPECS_FILE_LOCATION: " YOUR_APPCHAIN_SPECS_FILE_LOCATION
	exit 0 
	# 创建服务
	sudo tee /etc/systemd/system/appchain.service > /dev/null <<EOF
[Unit]
Description="Appchain systemd service"
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=on-failure
RestartSec=10
User=appchain_node_service
SyslogIdentifier=appchain
SyslogFacility=local7
KillSignal=SIGHUP
ExecStart=/var/lib/appchain-data/container-chain-template-frontier-node \
--chain=$YOUR_APPCHAIN_SPECS_FILE_LOCATION \
--rpc-port=9944 \
--name=para \
--base-path=/var/lib/appchain-data \
--bootnodes=$INSERT_YOUR_APPCHAIN_BOOTNODE \
-- \
--chain=/var/lib/appchain-data/westend-alphanet-raw-specs.json \
--rpc-port=9945 \
--name=relay \
--sync=fast \
--bootnodes=/dns4/frag3-stagenet-relay-val-0.g.moondev.network/tcp/30334/p2p/12D3KooWKvtM52fPRSdAnKBsGmST7VHvpKYeoSYuaAv5JDuAvFCc \
--bootnodes=/dns4/frag3-stagenet-relay-val-1.g.moondev.network/tcp/30334/p2p/12D3KooWQYLjopFtjojRBfTKkLFq2Untq9yG7gBjmAE8xcHFKbyq \
--bootnodes=/dns4/frag3-stagenet-relay-val-2.g.moondev.network/tcp/30334/p2p/12D3KooWMAtGe8cnVrg3qGmiwNjNaeVrpWaCTj82PGWN7PBx2tth \
--bootnodes=/dns4/frag3-stagenet-relay-val-3.g.moondev.network/tcp/30334/p2p/12D3KooWLKAf36uqBBug5W5KJhsSnn9JHFCcw8ykMkhQvW7Eus3U \
--bootnodes=/dns4/vira-stagenet-relay-validator-0.a.moondev.network/tcp/30334/p2p/12D3KooWSVTKUkkD4KBBAQ1QjAALeZdM3R2Kc2w5eFtVxbYZEGKd \
--bootnodes=/dns4/vira-stagenet-relay-validator-1.a.moondev.network/tcp/30334/p2p/12D3KooWFJoVyvLNpTV97SFqs91HaeoVqfFgRNYtUYJoYVbBweW4 \
--bootnodes=/dns4/vira-stagenet-relay-validator-2.a.moondev.network/tcp/30334/p2p/12D3KooWP1FA3dq1iBmEBYdQKAe4JNuzvEcgcebxBYMLKpTNirCR \
--bootnodes=/dns4/vira-stagenet-relay-validator-3.a.moondev.network/tcp/30334/p2p/12D3KooWDaTC6H6W1F4NkbaqK3Ema3jzc2BbhE2tyD3YEf84yNLE 

[Install]
WantedBy=multi-user.target
EOF
}

# 安装区块生产者节点
function install_block_producer_node() {

	# 用户参数
	read -p "节点名称: " tanssi_node_name
	read -p "生产者名称(请勿与上重复): " producer_name
	read -p "中继节点名称(请勿与上重复): " relay_node_name

	sudo apt update
    sudo apt upgrade -y

    # 检查 Docker 是否已安装
    if ! command -v docker &> /dev/null
    then
        echo "安装Docker..."
        sudo apt install  -y ca-certificates curl gnupg lsb-release docker.io
    else
        echo "Docker 已安装。"
    fi
    
    # 下载 Tanssi 应用链程序
	mkdir -p $HOME/tanssi-data
	wget -P $HOME/tanssi-data https://github.com/moondance-labs/tanssi/releases/download/v0.6.1/tanssi-node
	chmod +x $HOME/tanssi-data/*
	
	# 创建服务
	sudo tee /etc/systemd/system/tanssi.service > /dev/null <<EOF
[Unit]
Description="Tanssi systemd service"
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=on-failure
RestartSec=10
User=tanssi_service
SyslogIdentifier=tanssi
SyslogFacility=local7
KillSignal=SIGHUP
ExecStart=$HOME/tanssi-data/tanssi-node \
--chain=dancebox \
--name=$tanssi_node_name \
--sync=warp \
--base-path=$HOME/tanssi-data/para \
--state-pruning=2000 \
--blocks-pruning=2000 \
--collator \
--database paritydb \
--telemetry-url='wss://telemetry.polkadot.io/submit/ 0' 
-- \
--name=$producer_name \
--base-path=$HOME/tanssi-data/container \
--telemetry-url='wss://telemetry.polkadot.io/submit/ 0' 
-- \
--chain=westend_moonbase_relay_testnet \
--name=$relay_node_name \
--sync=fast \
--base-path=$HOME/tanssi-data/relay \
--state-pruning=2000 \
--blocks-pruning=2000 \
--database paritydb \
--telemetry-url='wss://telemetry.polkadot.io/submit/ 0' 

[Install]
WantedBy=multi-user.target
EOF

	# 启动服务
	systemctl enable tanssi.service
	systemctl start tanssi.service
	
	echo "==============================部署完成==================================="

}

# 查看区块生产者节点状态
function check_tanssi_service_status() {
    systemctl status tanssi.service
}

# 查看区块生产者节点日志
function view_tanssi_log() {
	journalctl -f -u tanssi.service
}

# 查看区块生产者节点秘钥
function view_tanssi_key() {
	curl http://127.0.0.1:9944 -H \
	"Content-Type:application/json;charset=utf-8" -d \
	  '{
	    "jsonrpc":"2.0",
	    "id":1,
	    "method":"author_rotateKeys",
	    "params": []
	  }'
}

# 停止节点
function stop_tanssi_node() {
	systemctl stop tanssi.service
}

# 启动节点
function start_tanssi_node() {
	systemctl start tanssi.service
}

# MENU
function main_menu() {
    while true; do
        clear
        echo "===============Tanssi Network一键部署脚本==============="
    	echo "沟通电报群：https://t.me/lumaogogogo"
    	echo "建设者节点：4C8G300G SSD，生产者节点：12C32G1T NVME"
        echo "请选择要执行的操作:"
        echo "---------------生产者节点相关选项----------------"
        echo "1. 部署区块生产者节点"
        echo "2. 区块生产者节点状态"
        echo "3. 区块生产者节点日志"
        echo "4. 区块生产者节点秘钥"
        echo "5. 启动区块生产者节点"
        echo "6. 停止区块生产者节点"
        #echo "---------------建设者节点相关选项---------------"
        echo "--------------------其他--------------------"
        echo "0. 退出脚本exit"
        read -p "请输入选项: " OPTION

        case $OPTION in
        1) install_block_producer_node ;;
        2) check_tanssi_service_status ;;
        3) view_tanssi_log ;;
        4) view_tanssi_key ;;
        5) start_tanssi_node ;;
        6) stop_tanssi_node ;;
        
        0) echo "退出脚本。"; exit 0 ;;
	    *) echo "无效选项，请重新输入。"; sleep 3 ;;
	    esac
	    echo "按任意键返回主菜单..."
        read -n 1
    done
}

# SHOW MENU
main_menu