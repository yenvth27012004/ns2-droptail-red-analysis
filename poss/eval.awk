BEGIN {
    tcp_recv = 0;
    udp_recv = 0;
    dropped = 0;
    start_time = 0.5;
    end_time = 15.0;
}
{
    event = $1; time = $2; node_to = $4; 
    pkt_type = $5; pkt_size = $6; flow_id = $8;

    # Tính Packet Loss (Fig 4, 7, 9)
    if (event == "d") {
        dropped++;
    }

    # Tính Throughput (Fig 3, 6)
    if (event == "r" && node_to == 4) {
        if (flow_id == 1) tcp_recv += pkt_size;
        if (flow_id == 2) udp_recv += pkt_size;
    }
}
END {
    duration = end_time - start_time;
    print "--- KẾT QUẢ THEO BÀI BÁO ---";
    printf "TCP Throughput: %.2f Kbps\n", (tcp_recv * 8) / (duration * 1024);
    printf "UDP Throughput: %.2f Kbps\n", (udp_recv * 8) / (duration * 1024);
    printf "Tổng số gói bị mất (Packet Loss): %d\n", dropped;
}
