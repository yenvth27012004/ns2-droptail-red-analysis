# ======================================================================
# PROJECT: PHÂN TÍCH HIỆU NĂNG TCP/UDP THEO KÍCH THƯỚC BỘ ĐỆM (NS2)
# MÔ PHỎNG THEO BÀI BÁO: Syed Humair Ali, et al. (PNEC-NUST)
# ======================================================================

set ns [new Simulator]

# --- [1. CẤU HÌNH THAM SỐ THÍ NGHIỆM] ---
# Thay đổi b_size từ 10, 20, 30, 40, 50... để lấy dữ liệu vẽ hình
set b_size 20                
set bottle_bw 0.1Mb          ;# Băng thông nút thắt (Theo bài báo)
set bottle_delay 50ms        ;# Trễ truyền lan (Theo bài báo)
set packet_size 1400         ;# Kích thước gói TCP (Theo bài báo)

# --- [2. QUẢN LÝ TRACE FILES] ---
set tf [open project.tr w]
$ns trace-all $tf
set nf [open project.nam w]
$ns namtrace-all $nf

# File ghi log Congestion Window (Để vẽ Fig 5 và Fig 8)
set f_cwnd [open cwnd_data.tr w]

# Màu sắc hiển thị trong NAM
$ns color 1 Blue   ;# TCP Flow
$ns color 2 Red    ;# UDP Flow

# --- [3. THIẾT LẬP TOPOLOGY - HÌNH QUẢ TẠ (FIG 2)] ---
set n0 [$ns node]; set n1 [$ns node]; set n2 [$ns node] ;# Sending Hosts
set n3 [$ns node]; set n4 [$ns node]                    ;# Bottleneck Nodes
set n5 [$ns node]; set n6 [$ns node]; set n7 [$ns node] ;# Receiving Hosts

# Các liên kết phía nguồn (100Mb theo bài báo)
$ns duplex-link $n0 $n3 100Mb 2ms DropTail
$ns duplex-link $n1 $n3 100Mb 2ms DropTail
$ns duplex-link $n2 $n3 100Mb 2ms DropTail

# Liên kết Bottleneck (Đây là nơi gây nghẽn và áp dụng cơ chế quản lý hàng đợi)
# Thay 'DropTail' bằng 'RED' để chạy kịch bản thứ 2 của bài báo
set q_type DropTail 
$ns duplex-link $n3 $n4 $bottle_bw $bottle_delay $q_type
$ns queue-limit $n3 $n4 $b_size

# Các liên kết phía đích
$ns duplex-link $n4 $n5 100Mb 2ms DropTail
$ns duplex-link $n4 $n6 100Mb 2ms DropTail
$ns duplex-link $n4 $n7 100Mb 2ms DropTail

# Cấu hình RED (Nếu chọn q_type là RED)
if { $q_type == "RED" } {
    set redq [[$ns link $n3 $n4] queue]
    $redq set thresh_ [expr $b_size * 0.25]
    $redq set maxthresh_ [expr $b_size * 0.5]
}

# --- [4. THIẾT LẬP LUỒNG DỮ LIỆU (MIXED TRAFFIC)] ---

# Thủ tục theo dõi Cửa sổ nghẽn (Congestion Window)
proc plotWindow {tcpSource file} {
    global ns
    set now [$ns now]
    set cwnd [$tcpSource set cwnd_]
    puts $file "$now $cwnd"
    $ns at [expr $now + 0.1] "plotWindow $tcpSource $file"
}

# Luồng TCP (Sử dụng Sack1 - tương đương Reno trong xử lý ACK nhưng chuyên nghiệp hơn)
set tcp [new Agent/TCP/Sack1]
$tcp set fid_ 1
$tcp set packetSize_ $packet_size
set sink [new Agent/TCPSink/Sack1]
$ns attach-agent $n0 $tcp
$ns attach-agent $n5 $sink
$ns connect $tcp $sink
set ftp [new Application/FTP]; $ftp attach-agent $tcp

# Luồng UDP (Poisson Traffic - Sử dụng Exponential)
set udp [new Agent/UDP]; $udp set fid_ 2
set exp [new Application/Traffic/Exponential]
$exp set rate_ 80k
$exp set packetSize_ 500
$exp attach-agent $udp
$ns attach-agent $n1 $udp
set null [new Agent/Null]
$ns attach-agent $n6 $null
$ns connect $udp $null

# --- [5. LỊCH TRÌNH MÔ PHỎNG] ---
$ns at 0.5 "$ftp start"
$ns at 0.5 "plotWindow $tcp $f_cwnd"
$ns at 1.0 "$exp start"

$ns at 15.0 "finish"

proc finish {} {
    global ns tf nf f_cwnd
    $ns flush-trace
    close $tf; close $nf; close $f_cwnd
    puts "Mô phỏng kết thúc. Đã tạo file project.tr và cwnd_data.tr"
    exit 0
}

$ns run
