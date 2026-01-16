set title "TCP Cwnd Comparison (Buffer Size = 20)"
set xlabel "Time (s)"
set ylabel "Cwnd (packets)"
plot "cwnd_dt_bsize_20.tr" with lines title "DropTail (With UDP Traffic)", \
     "cwnd_red_bsize_20.tr" with lines title "RED (With UDP Traffic)"
