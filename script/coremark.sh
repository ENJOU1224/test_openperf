# prepare the binary file
git clone https://github.com/OpenXiangShan/ready-to-run.git
# run the workload
./build/RISCV/gem5.opt ./configs/example/xiangshan.py --raw-cpt --generic-rv-cpt=./ready-to-run/coremark-2-iteration.bin
# get the ipc
grep 'cpu.ipc' m5out/stats.txt
