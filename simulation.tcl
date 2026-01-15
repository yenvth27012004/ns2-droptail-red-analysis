# ======================================================================
# PROJECT: PHÂN TÍCH SONG SONG DROPTAIL & RED (CÓ CƠ CHẾ ACK)
# MÔ HÌNH: 6 Clients -> 2 Routers (Bottleneck) -> 1 Server
# ======================================================================

set ns [new Simulator]

# Định nghĩa màu sắc cho Flow ID (FID)
$ns color 1 Blue      ;# Nhánh DropTail - TCP (ACK)
$ns color 2 Red       ;# Nhánh DropTail - UDP (No-ACK)
$ns color 3 SeaGreen  ;# Nhánh RED - TCP (ACK)
$ns color 4 Orange    ;# Nhánh RED - UDP (No-ACK)

set tf [open project.tr w]
$ns trace-all $tf
set nf [open project.nam w]
$ns namtrace-all $nf

# --- 1. KHỞI TẠO CÁC NÚT (NODES) ---
# Clients nhánh DropTail (Bên trái, phía trên)
set c0 [$ns node]
set c1 [$ns node]
set c2 [$ns node]

# Clients nhánh RED (Bên trái, phía dưới)
set c3 [$ns node]
set c4 [$ns node]
set c5 [$ns node]

# Routers trung tâm và Server đích (Bên phải)
set r_dt  [$ns node]; # Router quản lý DropTail
set r_red [$ns node]; # Router quản lý RED
set svr   [$ns node]; # Server nhận duy nhất

# --- 2. THIẾT LẬP LIÊN KẾT VÀ ĐỊNH HƯỚNG (LAYOUT) ---

# Kết nối Clients 0,1,2 đến Router DropTail
$ns duplex-link $c0 $r_dt 10Mb 2ms DropTail
$ns duplex-link $c1 $r_dt 10Mb 2ms DropTail
$ns duplex-link $c2 $r_dt 10Mb 2ms DropTail

# Kết nối Clients 3,4,5 đến Router RED
$ns duplex-link $c3 $r_red 10Mb 2ms DropTail
$ns duplex-link $c4 $r_red 10Mb 2ms DropTail
$ns duplex-link $c5 $r_red 10Mb 2ms DropTail

# Thiết lập Bottleneck chung (Truyền về Server)
$ns duplex-link $r_dt  $svr 1.5Mb 50ms DropTail
$ns duplex-link $r_red $svr 1.5Mb 50ms RED

# Cấu hình hiển thị NAM (Trái sang Phải)
$ns duplex-link-op $c0 $r_dt orient right-down
$ns duplex-link-op $c1 $r_dt orient right
$ns duplex-link-op $c2 $r_dt orient right-up

$ns duplex-link-op $c3 $r_red orient right-down
$ns duplex-link-op $c4 $r_red orient right
$ns duplex-link-op $c5 $r_red orient right-up

$ns duplex-link-op $r_dt  $svr orient right-down
$ns duplex-link-op $r_red $svr orient right-up

# Giám sát hàng đợi tại 2 điểm nghẽn
$ns duplex-link-op $r_dt  $svr queuePos 0.5
$ns duplex-link-op $r_red $svr queuePos 0.5

# --- 3. THIẾT LẬP AGENTS VÀ TRAFFIC (CÓ ACK) ---

# --- NHÁNH 1: DROPTAIL ---
# Client 0: TCP Sack (Có ACK)
set tcp0 [new Agent/TCP/Sack1]
$tcp0 set fid_ 1
set sink0 [new Agent/TCPSink/Sack1]
$ns attach-agent $c0 $tcp0
$ns attach-agent $svr $sink0
$ns connect $tcp0 $sink0
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0

# Client 1: UDP (Exponential - Poisson)
set udp1 [new Agent/UDP]
$udp1 set fid_ 2
set null1 [new Agent/LossMonitor]
$ns attach-agent $c1 $udp1
$ns attach-agent $svr $null1
$ns connect $udp1 $null1
set exp1 [new Application/Traffic/Exponential]
$exp1 set rate_ 800k
$exp1 attach-agent $udp1

# Client 2: UDP (Pareto - Burst)
set udp2 [new Agent/UDP]
$udp2 set fid_ 2
set null2 [new Agent/LossMonitor]
$ns attach-agent $c2 $udp2
$ns attach-agent $svr $null2
$ns connect $udp2 $null2
set par2 [new Application/Traffic/Pareto]
$par2 set rate_ 800k
$par2 attach-agent $udp2

# --- NHÁNH 2: RED ---
# Client 3: TCP Sack (Có ACK)
set tcp3 [new Agent/TCP/Sack1]
$tcp3 set fid_ 3
set sink3 [new Agent/TCPSink/Sack1]
$ns attach-agent $c3 $tcp3
$ns attach-agent $svr $sink3
$ns connect $tcp3 $sink3
set ftp3 [new Application/FTP]
$ftp3 attach-agent $tcp3

# Client 4: UDP (Exponential - Poisson)
set udp4 [new Agent/UDP]
$udp4 set fid_ 4
set null4 [new Agent/LossMonitor]
$ns attach-agent $c4 $udp4
$ns attach-agent $svr $null4
$ns connect $udp4 $null4
set exp4 [new Application/Traffic/Exponential]
$exp4 set rate_ 800k
$exp4 attach-agent $udp4

# Client 5: UDP (Pareto - Burst)
set udp5 [new Agent/UDP]
$udp5 set fid_ 4
set null5 [new Agent/LossMonitor]
$ns attach-agent $c5 $udp5
$ns attach-agent $svr $null5
$ns connect $udp5 $null5
set par5 [new Application/Traffic/Pareto]
$par5 set rate_ 800k
$par5 attach-agent $udp5

# --- 4. LẬP LỊCH CHẠY ---
$ns at 0.5 "$ftp0 start"; $ns at 0.5 "$ftp3 start"
$ns at 1.0 "$exp1 start"; $ns at 1.0 "$exp4 start"
$ns at 1.5 "$par2 start"; $ns at 1.5 "$par5 start"

$ns at 14.0 "$ftp0 stop"; $ns at 14.0 "$ftp3 stop"
$ns at 14.0 "$exp1 stop"; $ns at 14.0 "$exp4 stop"
$ns at 14.0 "$par2 stop"; $ns at 14.0 "$par5 stop"

proc finish {} {
    global ns tf nf
    $ns flush-trace
    close $tf
    close $nf
    exec nam project.nam &
    exit 0
}

$ns at 15.0 "finish"
$ns run
