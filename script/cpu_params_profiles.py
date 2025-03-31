def haha(args, system):
    return

def set_frontend_bottleneck_params(args, system):
    """测试前端瓶颈敏感性（取指/译码/分支预测）"""
    for cpu in system.cpu:
        # 流水线延迟控制
        cpu.commitToFetchDelay = 6  # 增加前端延迟
        cpu.fetchToDecodeDelay = 4  # 原2 → 增加传输延迟
        
        # 资源限制
        cpu.fetchQueueSize = 16      # 缩小取指队列
        cpu.decodeWidth = 4          # 减半译码带宽
        cpu.renameWidth = 4          # 同步减小重命名带宽
        
        # 分支预测限制
        if hasattr(cpu, 'branchPred'):
            cpu.branchPred.predictWidth = 16
            cpu.branchPred.ftq_size = 64   # 原256 → 减小FTQ容量
            cpu.branchPred.fsq_size = 64

def set_execution_contention_params(args, system):
    """测试执行单元竞争敏感性（发射/乱序窗口/依赖检测）"""
    for cpu in system.cpu:
        # 执行资源限制
        cpu.dispWidth = [4,4,4]      # 减少发射端口
        cpu.commitWidth = 6           # 原12 → 减半提交带宽
        
        # 乱序窗口限制
        cpu.numROBEntries = 128       # 减小重排序缓冲区
        cpu.numPhysIntRegs = 128      # 原354 → 减少物理寄存器
        cpu.numDQEntries = [8,4,4]    # 缩小依赖队列
        
        # 存储相关放宽（避免干扰测试目标）
        cpu.LQEntries = 256          # 增大避免成为瓶颈
        cpu.SQEntries = 192

def set_memory_subsystem_params(args, system):
    """测试存储子系统敏感性（Load/Store队列/缓存）"""
    for cpu in system.cpu:
        # 存储队列限制
        cpu.LQEntries = 32            # 原128 → 激进缩小
        cpu.SQEntries = 24            # 原96 → 减小存储队列
        cpu.SbufferEntries = 4        # 原24 → 极小存储缓冲区
        
        # 缓存系统限制
        if args.caches:
            cpu.dcache.mshrs = 4       # 原32 → 减少未完成请求
            cpu.dcache.tag_load_read_ports = 4  # 原100 → 限制tag访问
            
        # 执行资源放宽（避免干扰）
        cpu.dispWidth = [16,16,16]    # 增大确保不是瓶颈

def set_branch_prediction_params(args, system):
    """测试分支预测敏感性（预测器容量/恢复机制）"""
    for cpu in system.cpu:
        if hasattr(cpu, 'branchPred'):
            # 预测器资源限制
            bp = cpu.branchPred
            bp.uftb.numEntries = 64    # 原1024 → 极简BTB
            bp.ftb.numEntries = 256    # 原16384 → 大幅缩小
            bp.tage.baseTableSize = 1024  # 原16384 → 缩小基础表
            
            # 预测流水线限制
            bp.predictWidth = 8        # 原64 → 严格限制
            bp.fsq_size = 32           # 原256 → 减小恢复队列
            bp.ftq_size = 32
            
            # 历史长度调整
            bp.tage.histLengths = [4,7,12]  # 原长历史截断
            bp.tage.numPredictors = 2  # 原14 → 减少预测器数量

def set_cache_hierarchy_params(args, system):
    """测试缓存层次敏感性（容量/MSHR/延迟）"""
    # L1缓存限制
    for cpu in system.cpu:
        if args.caches:
            cpu.icache.size = '32kB'    # 原128kB
            cpu.dcache.size = '32kB'
            cpu.dcache.mshrs = 8        # 原32
    
    # L2缓存限制
    if args.l2cache:
        for i in range(args.num_cpus):
            system.l2_caches[i].size = '512kB'  # 原2MB
            system.l2_caches[i].mshrs = 16       # 默认值通常32-64
            system.tol2bus_list[i].forward_latency = 4  # 增加总线延迟
    
    # L3缓存限制
    if args.l3cache:
        system.l3.size = '2MB'         # 典型值通常8MB+
        system.l3.mshrs = 32           # 原128

# 配置映射字典（方便统一调用）
param_profiles = {
    'frontend': set_frontend_bottleneck_params,
    'execution': set_execution_contention_params,
    'memory': set_memory_subsystem_params,
    'branch': set_branch_prediction_params,
    'cache': set_cache_hierarchy_params,
    None: haha,  
    '': haha     
}
