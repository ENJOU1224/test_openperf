def haha(args, system):
    return

def set_frontend_bottleneck_params_L0(args, system):
    """测试前端瓶颈敏感性（取指/译码/分支预测）"""
    for cpu in system.cpu:
        # 流水线延迟控制
        cpu.commitToFetchDelay = 3  # 
        cpu.fetchToDecodeDelay = 3  # 

        # 资源限制
        cpu.fetchQueueSize = 48      #
        cpu.decodeWidth = 6          #
        cpu.renameWidth = 6          # 
        cpu.dispWidth = [8,8,8]      #

def set_frontend_bottleneck_params_L1(args, system):
    """测试前端瓶颈敏感性（取指/译码/分支预测）"""
    for cpu in system.cpu:
        # 流水线延迟控制
        cpu.commitToFetchDelay = 4  # 增加前端延迟
        cpu.fetchToDecodeDelay = 4  # 原2 → 增加传输延迟
        
        # 资源限制
        cpu.fetchQueueSize = 32      # 缩小取指队列
        cpu.decodeWidth = 4          # 减半译码带宽
        cpu.renameWidth = 4          # 同步减小重命名带宽
        cpu.dispWidth = [6,6,6]      # 减少发射端口

def set_frontend_bottleneck_params_L2(args, system):
    """测试前端瓶颈敏感性（取指/译码/分支预测）"""
    for cpu in system.cpu:
        # 流水线延迟控制
        cpu.commitToFetchDelay = 6  # 增加前端延迟
        cpu.fetchToDecodeDelay = 4  # 原2 → 增加传输延迟
        
        # 资源限制
        cpu.fetchQueueSize = 24      # 缩小取指队列
        cpu.decodeWidth = 3          # 减半译码带宽
        cpu.renameWidth = 3          # 同步减小重命名带宽
        cpu.dispWidth = [5,5,5]      # 减少发射端口

def set_execution_contention_params_L0(args, system):
    """测试执行单元竞争敏感性（发射/乱序窗口/依赖检测）"""
    for cpu in system.cpu:
        # 执行资源限制
        cpu.commitWidth = 10           # 原12 → 减半提交带宽
        
        # 乱序窗口限制
        cpu.numROBEntries = 480       # 减小重排序缓冲区
        cpu.numPhysIntRegs = 256      # 原354 → 减少物理寄存器
        cpu.numDQEntries = [24,12,12]    # 缩小依赖队列
        
        # 存储相关放宽（避免干扰测试目标）
        cpu.LQEntries = 256          # 增大避免成为瓶颈
        cpu.SQEntries = 192

def set_execution_contention_params_L1(args, system):
    """测试执行单元竞争敏感性（发射/乱序窗口/依赖检测）"""
    for cpu in system.cpu:
        # 执行资源限制
        cpu.commitWidth = 8           # 原12 → 减半提交带宽
        
        # 乱序窗口限制
        cpu.numROBEntries = 320       # 减小重排序缓冲区
        cpu.numPhysIntRegs = 192      # 原354 → 减少物理寄存器
        cpu.numDQEntries = [20,10,10]    # 缩小依赖队列
        
        # 存储相关放宽（避免干扰测试目标）
        cpu.LQEntries = 256          # 增大避免成为瓶颈
        cpu.SQEntries = 192

def set_execution_contention_params_L2(args, system):
    """测试执行单元竞争敏感性（发射/乱序窗口/依赖检测）"""
    for cpu in system.cpu:
        # 执行资源限制
        cpu.commitWidth = 6           # 原12 → 减半提交带宽
        
        # 乱序窗口限制
        cpu.numROBEntries = 240       # 减小重排序缓冲区
        cpu.numPhysIntRegs = 128      # 原354 → 减少物理寄存器
        cpu.numDQEntries = [16,8,8]    # 缩小依赖队列
        
        # 存储相关放宽（避免干扰测试目标）
        cpu.LQEntries = 256          # 增大避免成为瓶颈
        cpu.SQEntries = 192

def set_memory_subsystem_params_L0(args, system):
    """测试存储子系统敏感性（Load/Store队列/缓存）"""
    for cpu in system.cpu:
        # 存储队列限制
        cpu.LQEntries = 96            # 原128 → 激进缩小
        cpu.SQEntries = 72            # 原96 → 减小存储队列
        cpu.SbufferEntries = 20        # 原24 → 极小存储缓冲区
        
        # 缓存系统限制
        if args.caches:
            cpu.dcache.mshrs = 24       # 原32 → 减少未完成请求
            
        # 执行资源放宽（避免干扰）
        cpu.dispWidth = [16,16,16]    # 增大确保不是瓶颈

def set_memory_subsystem_params_L1(args, system):
    """测试存储子系统敏感性（Load/Store队列/缓存）"""
    for cpu in system.cpu:
        # 存储队列限制
        cpu.LQEntries = 72            # 原128 → 激进缩小
        cpu.SQEntries = 64            # 原96 → 减小存储队列
        cpu.SbufferEntries = 16        # 原24 → 极小存储缓冲区
        
        # 缓存系统限制
        if args.caches:
            cpu.dcache.mshrs = 20       # 原32 → 减少未完成请求
            cpu.dcache.tag_load_read_ports = 4  # 原100 → 限制tag访问
            
        # 执行资源放宽（避免干扰）
        cpu.dispWidth = [16,16,16]    # 增大确保不是瓶颈

def set_memory_subsystem_params_L2(args, system):
    """测试存储子系统敏感性（Load/Store队列/缓存）"""
    for cpu in system.cpu:
        # 存储队列限制
        cpu.LQEntries = 48            # 原128 → 激进缩小
        cpu.SQEntries = 48            # 原96 → 减小存储队列
        cpu.SbufferEntries = 12        # 原24 → 极小存储缓冲区
        
        # 缓存系统限制
        if args.caches:
            cpu.dcache.mshrs = 8       # 原32 → 减少未完成请求
            cpu.dcache.tag_load_read_ports = 4  # 原100 → 限制tag访问
            
        # 执行资源放宽（避免干扰）
        cpu.dispWidth = [16,16,16]    # 增大确保不是瓶颈

def set_branch_prediction_params_L0(args, system):
    """测试分支预测敏感性（预测器容量/恢复机制）"""
    for cpu in system.cpu:
        if hasattr(cpu, 'branchPred'):
            # 预测器资源限制
            bp = cpu.branchPred
            bp.uftb.numEntries = 512    # 原1024 → 极简BTB
            bp.ftb.numEntries = 8192    # 原16384 → 大幅缩小
            bp.tage.baseTableSize = 8192  # 原16384 → 缩小基础表
            
            # 预测流水线限制
            bp.predictWidth = 48        # 原64 → 严格限制
            bp.fsq_size = 192           # 原256 → 减小恢复队列
            bp.ftq_size = 192 
            
            # 历史长度调整
            bp.tage.histLengths = [4, 7, 12, 16, 21, 29, 38, 51, 68, 90, 120, 160 ]  # 原长历史截断
            bp.tage.numPredictors = 12  # 原14 → 减少预测器数量

def set_branch_prediction_params_L1(args, system):
    """测试分支预测敏感性（预测器容量/恢复机制）"""
    for cpu in system.cpu:
        if hasattr(cpu, 'branchPred'):
            # 预测器资源限制
            bp = cpu.branchPred
            bp.uftb.numEntries = 256    # 原1024 → 极简BTB
            bp.ftb.numEntries = 4096    # 原16384 → 大幅缩小
            bp.tage.baseTableSize = 4096  # 原16384 → 缩小基础表
            
            # 预测流水线限制
            bp.predictWidth = 32        # 原64 → 严格限制
            bp.fsq_size = 144           # 原256 → 减小恢复队列
            bp.ftq_size = 144
            
            # 历史长度调整
            bp.tage.histLengths = [4, 7, 12, 16, 21, 29, 38, 51, 68, 90 ]  # 原长历史截断
            bp.tage.numPredictors = 10  # 原14 → 减少预测器数量

def set_branch_prediction_params_L2(args, system):
    """测试分支预测敏感性（预测器容量/恢复机制）"""
    for cpu in system.cpu:
        if hasattr(cpu, 'branchPred'):
            # 预测器资源限制
            bp = cpu.branchPred
            bp.uftb.numEntries = 128    # 原1024 → 极简BTB
            bp.ftb.numEntries = 2048    # 原16384 → 大幅缩小
            bp.tage.baseTableSize = 2048  # 原16384 → 缩小基础表
            
            # 预测流水线限制
            bp.predictWidth = 16        # 原64 → 严格限制
            bp.fsq_size = 128           # 原256 → 减小恢复队列
            bp.ftq_size = 128 
            
            # 历史长度调整
            bp.tage.histLengths = [4, 7, 12, 16, 21, 29, 38, 51]  # 原长历史截断
            bp.tage.numPredictors = 8  # 原14 → 减少预测器数量

def set_cache_hierarchy_params_L0(args, system):
    """测试缓存层次敏感性（容量/MSHR/延迟）"""
    # L1缓存限制
    for cpu in system.cpu:
        if args.caches:
            cpu.icache.size = '64kB'    # 原128kB
            cpu.dcache.size = '64kB'
            cpu.dcache.mshrs = 24        # 原32
    
    # L2缓存限制
    if args.l2cache:
        for i in range(args.num_cpus):
            system.l2_caches[i].size = '1MB'  # 原2MB
            system.tol2bus_list[i].forward_latency = 1  # 增加总线延迟
    
    # L3缓存限制
    if args.l3cache:
        system.l3.size = '4MB'         # 典型值通常8MB+
        system.l3.mshrs = 96           # 原128

def set_cache_hierarchy_params_L1(args, system):
    """测试缓存层次敏感性（容量/MSHR/延迟）"""
    # L1缓存限制
    for cpu in system.cpu:
        if args.caches:
            cpu.icache.size = '32kB'    # 原128kB
            cpu.dcache.size = '32kB'
            cpu.dcache.mshrs = 16        # 原32
    
    # L2缓存限制
    if args.l2cache:
        for i in range(args.num_cpus):
            system.l2_caches[i].size = '512kB'  # 原2MB
            system.tol2bus_list[i].forward_latency = 2  # 增加总线延迟
    
    # L3缓存限制
    if args.l3cache:
        system.l3.size = '2MB'         # 典型值通常8MB+
        system.l3.mshrs = 64           # 原128

def set_cache_hierarchy_params_L2(args, system):
    """测试缓存层次敏感性（容量/MSHR/延迟）"""
    # L1缓存限制
    for cpu in system.cpu:
        if args.caches:
            cpu.icache.size = '16kB'    # 原128kB
            cpu.dcache.size = '16kB'
            cpu.dcache.mshrs = 12        # 原32
    
    # L2缓存限制
    if args.l2cache:
        for i in range(args.num_cpus):
            system.l2_caches[i].size = '256kB'  # 原2MB
            system.tol2bus_list[i].forward_latency = 4  # 增加总线延迟
    
    # L3缓存限制
    if args.l3cache:
        system.l3.size = '1MB'         # 典型值通常8MB+
        system.l3.mshrs = 48           # 原128

# 配置映射字典（方便统一调用）
param_profiles = {
    'frontend_L0': set_frontend_bottleneck_params_L0,
    'frontend_L1': set_frontend_bottleneck_params_L1,
    'frontend_L2': set_frontend_bottleneck_params_L2,
    'execution_L0': set_execution_contention_params_L0,
    'execution_L1': set_execution_contention_params_L1,
    'execution_L2': set_execution_contention_params_L2,
    'memory_L0': set_memory_subsystem_params_L0,
    'memory_L1': set_memory_subsystem_params_L1,
    'memory_L2': set_memory_subsystem_params_L2,
    'branch_L0': set_branch_prediction_params_L0,
    'branch_L1': set_branch_prediction_params_L1,
    'branch_L2': set_branch_prediction_params_L2,
    'cache_L0': set_cache_hierarchy_params_L0,
    'cache_L1': set_cache_hierarchy_params_L1,
    'cache_L2': set_cache_hierarchy_params_L2,
    None: haha,  
    '': haha     
}
