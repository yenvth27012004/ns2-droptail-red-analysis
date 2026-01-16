set ns [new Simulator]

# --- [1. CẤU HÌNH THAM SỐ BIẾN THIÊN] ---
# Bạn thay đổi con số này (10, 20, 50, 100) để lấy các kết quả khác nhau
set b_size 10 

# Định nghĩa màu sắc cho NAM
$ns color 1 Blue      ;# Nhánh DropTail - TCP
$ns color 2 Red       ;# Nhánh DropTail - UDP
$ns color 3 SeaGreen  ;# Nhánh RED - TCP
$ns color 4 Orange    ;# Nhánh RED - UDP

set tf [open project.tr w]
$ns trace-all $tf
set nf [open project.nam w]
$ns namtrace-all $nf

# Tự động tạo tên file log cwnd theo giá trị buffer size
set f_cwnd_dt [open "cwnd_dt_bsize_$b_size.tr" w]
set f_cwnd_red [open "cwnd_red_bsize_$b_size.tr" w]

# --- [2. KHỞI TẠO CÁC NÚT (NODES)] ---
set c0 [$ns node]; set c1 [$ns node]; set c2 [$ns node] ;# Clients nhánh DT
set c3 [$ns node]; set c4 [$ns node]; set c5 [$ns node] ;# Clients nhánh RED
set r_dt  [$ns node]; # Router DropTail
set r_red [$ns node]; # Router RED
set svr   [$ns node]; # Server đích chung

# --- [3. THIẾT LẬP LIÊN KẾT VÀ LAYOUT NAM] ---
# Nhánh DropTail
$ns duplex-link $c0 $r_dt 10Mb 2ms DropTail
$ns duplex-link $c1 $r_dt 10Mb 2ms DropTail
$ns duplex-link $c2 $r_dt 10Mb 2ms DropTail

# Nhánh RED
$ns duplex-link $c3 $r_red 10Mb 2ms DropTail
$ns duplex-link $c4 $r_red 10Mb 2ms DropTail
$ns duplex-link $c5 $r_red 10Mb 2ms DropTail

# Bottleneck chung về Server (Áp dụng Buffer Size thực nghiệm)
$ns duplex-link $r_dt  $svr 1.5Mb 50ms DropTail
$ns duplex-link $r_red $svr 1.5Mb 50ms RED

# Cấu hình hàng đợi (Queue Limit)
$ns queue-limit $r_dt  $svr $b_size
$ns queue-limit $r_red $svr $b_size

# Cấu hình tham số RED (Ngưỡng cảnh báo sớm)
set redq [[$ns link $r_red $svr] queue]
$redq set thresh_ [expr $b_size * 0.25]
$redq set maxthresh_ [expr $b_size * 0.5]

# Định hướng hiển thị trong NAM (Giữ nguyên cấu trúc bạn yêu cầu)
$ns duplex-link-op $c0 $r_dt orient right-down
$ns duplex-link-op $c1 $r_dt orient right
$ns duplex-link-op $c2 $r_dt orient right-up
$ns duplex-link-op $c3 $r_red orient right-down
$ns duplex-link-op $c4 $r_red orient right
$ns duplex-link-op $c5 $r_red orient right-up
$ns duplex-link-op $r_dt  $svr orient right-down
$ns duplex-link-op $r_red $svr orient right-up
$ns duplex-link-op $r_dt  $svr queuePos 0.5
$ns duplex-link-op $r_red $svr queuePos 0.5

# --- [4. THIẾT LẬP AGENTS VÀ TRAFFIC MONITORING] ---

# Thủ tục ghi log Cwnd (Theo dõi cửa sổ nghẽn TCP)
proc plotWindow {tcpSource file} {
    global ns
    set now [$ns now]
    set cwnd [$tcpSource set cwnd_]
    puts $file "$now $cwnd"
    $ns at [expr $now + 0.1] "plotWindow $tcpSource $file"
}

# NHÁNH 1: DROPTAIL
set tcp0 [new Agent/TCP/Sack1]; $tcp0 set fid_ 1
set sink0 [new Agent/TCPSink/Sack1]
$ns attach-agent $c0 $tcp0; $ns attach-agent $svr $sink0
$ns connect $tcp0 $sink0
set ftp0 [new Application/FTP]; $ftp0 attach-agent $tcp0

set udp1 [new Agent/UDP]; $udp1 set fid_ 2
set null1 [new Agent/Null]
$ns attach-agent $c1 $udp1; $ns attach-agent $svr $null1
$ns connect $udp1 $null1
set exp1 [new Application/Traffic/Exponential]
$exp1 set rate_ 800k; $exp1 attach-agent $udp1

# NHÁNH 2: RED
set tcp3 [new Agent/TCP/Sack1]; $tcp3 set fid_ 3
set sink3 [new Agent/TCPSink/Sack1]
$ns attach-agent $c3 $tcp3; $ns attach-agent $svr $sink3
$ns connect $tcp3 $sink3
set ftp3 [new Application/FTP]; $ftp3 attach-agent $tcp3

set udp4 [new Agent/UDP]; $udp4 set fid_ 4
set null4 [new Agent/Null]
$ns attach-agent $c4 $udp4; $ns attach-agent $svr $null4
$ns connect $udp4 $null4
set exp4 [new Application/Traffic/Exponential]
$exp4 set rate_ 800k; $exp4 attach-agent $udp4

# --- [5. LỊCH TRÌNH VÀ KẾT THÚC] ---
$ns at 0.5 "$ftp0 start"; $ns at 0.5 "$ftp3 start"
$ns at 0.5 "plotWindow $tcp0 $f_cwnd_dt"
$ns at 0.5 "plotWindow $tcp3 $f_cwnd_red"
$ns at 1.0 "$exp1 start"; $ns at 1.0 "$exp4 start"

$ns at 14.5 "$ftp0 stop"; $ns at 14.5 "$ftp3 stop"
$ns at 15.0 "finish"

proc finish {} {
    global ns tf nf f_cwnd_dt f_cwnd_red
    $ns flush-trace
    close $tf; close $nf
    close $f_cwnd_dt; close $f_cwnd_red
    exit 0
}

$ns run
