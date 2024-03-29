// This is the configuration schema for fddaqconf_gen
//

local moo = import "moo.jsonnet";

local stypes = import "daqconf/types.jsonnet";
local types = moo.oschema.hier(stypes).dunedaq.daqconf.types;

local snicreader = import "dpdklibs/nicreader.jsonnet";
local nicreader_cfg = moo.oschema.hier(snicreader).dunedaq.dpdklibs.nicreader;

local s = moo.oschema.schema("dunedaq.fddaqconf.readoutgen");
local nc = moo.oschema.numeric_constraints;
// A temporary schema construction context.
local cs = {

  float4 : s.number("float4", "f4", doc="A float of 4 bytes"),

  id_list:    s.sequence( "IDList",   types.count, doc="List of Ids"),

  data_file_entry: s.record("data_file_entry", [
    s.field( "data_file", types.path, default='./frames.bin', doc="File containing data frames to be replayed by the fake cards. Former -d. Uses the asset manager, can also be 'asset://checksum/somelonghash', or 'file://somewhere/frames.bin' or 'frames.bin'"),
    s.field( "detector_id", types.count, default=3, doc="Detector ID that this file applies to"),
  ]),
  data_files: s.sequence("data_files", self.data_file_entry),

  numa_exception:  s.record( "NUMAException", [
    s.field( "host", types.host, default='localhost', doc="Host of exception"),
    s.field( "card", types.count, default=0, doc="Card ID of exception"),
    s.field( "numa_id", types.count, default=0, doc="NUMA ID of exception"),
    s.field( "felix_card_id", types.count, default=-1, doc="CARD ID override, -1 indicates no override"),
    s.field( "latency_buffer_numa_aware", types.flag, default=false, doc="Enable NUMA-aware mode for the Latency Buffer"),
    s.field( "latency_buffer_preallocation", types.flag, default=false, doc="Enable Latency Buffer preallocation"),
  ], doc="Exception to the default NUMA ID for FELIX cards"),

  numa_exceptions: s.sequence( "NUMAExceptions", self.numa_exception, doc="Exceptions to the default NUMA ID"),

  numa_config: s.record("numa_config", [
    s.field( "default_id", types.count, default=0, doc="Default NUMA ID for FELIX cards"),
    s.field( "default_latency_numa_aware", types.flag, default=false, doc="Default for Latency Buffer NUMA awareness"),
    s.field( "default_latency_preallocation", types.flag, default=false, doc="Default for Latency Buffer Preallocation"),
    s.field( "exceptions", self.numa_exceptions, default=[], doc="Exceptions to the default NUMA ID"),
  ]),

  dpdk_lcore_exception:  s.record( "DPDKLCoreException", [
    s.field( "host", types.host, default='localhost', doc="Host of exception"),
    s.field( "iface", types.count, default=0, doc="Card ID of exception"),
    s.field( "lcore_id_set", self.id_list, default=[], doc='List of IDs per core'),
  ]),
  dpdk_lcore_exceptions: s.sequence( "DPDKLCoreExceptions", self.dpdk_lcore_exception, doc="Exceptions to the default LCore config"),

  dpdk_lcore_config: s.record("DPDKLCoreConfig", [
    s.field( "default_lcore_id_set", self.id_list, default=[1,2,3,4], doc='List of IDs per core'),
    s.field( "exceptions", self.dpdk_lcore_exceptions, default=[], doc="Exceptions to the default NUMA ID"),
  ]),


  thread_pinning_file: s.record("ThreadPinningFile", [
    s.field( "after", types.string, default="", doc="When to execute the thread pinning script with this file, for example specifying boot will execute the threadpinning after boot"),
    s.field( "file", types.path, default="", doc="A thread pinning configuration file"),
  ]),
  thread_pinning_files: s.sequence( "ThreadPinningFiles", self.thread_pinning_file, doc="A list of thread pinning files"),

  readout: s.record("readout", [
    s.field( "detector_readout_map_file", types.path, default='./DetectorReadoutMap.json', doc="File containing detector hardware map for configuration to run"),
    s.field( "use_fake_data_producers", types.flag, default=false, doc="Use fake data producers that respond with empty fragments immediately instead of (fake) cards and DLHs"),
    // s.field( "memory_limit_gb", types.count, default=64, doc="Application memory limit in GB")
    // Fake cards
    s.field( "use_fake_cards", types.flag, default=false, doc="Use fake cards"),
    s.field( "generate_periodic_adc_pattern", types.flag, default=false, doc="Generate a periodic ADC pattern inside the input data. Only when FakeCard reader is used"),
    s.field( "emulated_TP_rate_per_ch", types.float4, default=1.0, doc="Rate of TPs per channel when using a periodic ADC pattern generation. Values expresses as multiples of the expected rate of 100 Hz/ch"),
    s.field( "emulated_data_times_start_with_now", types.flag, default=false, doc="If active, the timestamp of the first emulated data frame is set to the current wallclock time"),
    s.field( "default_data_file", types.path, default='asset://?label=ProtoWIB&subsystem=readout', doc="File containing data frames to be replayed by the fake cards. Former -d. Uses the asset manager, can also be 'asset://?checksum=somelonghash', or 'file://somewhere/frames.bin' or 'frames.bin'"),
    s.field( "data_files", self.data_files, default=[], doc="Files to use by detector type"),
    // DPDK
    s.field( "dpdk_eal_args", types.string, default="", doc='Args passed to the EAL in DPDK'),
    s.field( "dpdk_enable_callback_bypass", types.flag, default=false, doc='Enable callback bypass'),
    s.field( "dpdk_iface_config", nicreader_cfg.InterfaceParameters, default=nicreader_cfg.InterfaceParameters, doc="Configuration of DPDK interface"),
    s.field( "dpdk_lcores_config", self.dpdk_lcore_config, default=self.dpdk_lcore_config, doc='Configuration of DPDK LCore IDs'),
    // FLX
    s.field( "numa_config", self.numa_config, default=self.numa_config, doc='Configuration of FELIX NUMA IDs'),
    // DLH
    s.field( "emulator_mode", types.flag, default=false, doc="If active, timestamps of data frames are overwritten when processed by the readout. This is necessary if the felix card does not set correct timestamps. Former -e"),
    s.field( "thread_pinning_files", self.thread_pinning_files, default=[], doc="A list of thread pinning configuration files that gets executed when specified."),
    s.field( "source_queue_timeout_ms", types.count, default=0, doc="The source queue timeout that will be used in the datalink handle when polling source queues"),
    s.field( "source_queue_sleep_us", types.count, default=500, doc="The source queue seep that will be used in the datalink handle when polling source queues."),

    // s.field( "data_rate_slowdown_factor",types.count, default=1, doc="Factor by which to suppress data generation. Former -s"),
    s.field( "latency_buffer_size", types.count, default=499968, doc="Size of the latency buffers (in number of elements)"),
    s.field( "fragment_send_timeout_ms", types.count, default=10, doc="The send timeout that will be used in the readout modules when sending fragments downstream (i.e. to the TRB)."),
    s.field( "enable_tpg", types.flag, default=false, doc="Enable TPG"),
    s.field( "tpg_threshold", types.count, default=120, doc="Select TPG threshold"),
    s.field( "tpg_rs_memory_factor", types.float4, default=0.8, doc="Memory factor (R) for the TPG running sum algorithms"),
    s.field( "tpg_rs_scale_factor", types.count, default=2, doc="Scale factor for the TPG running sum algorithms"),
    s.field( "tpg_frugal_streaming_accumulator_limit", types.count, default=10, doc="Accumulator limit for the frugal streaming method"),
    s.field( "tpg_algorithm", types.string, default="SimpleThreshold", doc="Select TPG algorithm (SimpleThreshold, AbsRS)"),
    s.field( "enable_simple_threshold_on_collection", types.flag, default=false, doc="Enable SimpleThreshold TPG algorithm only on collection planes when a Running Sum algorithm is enabled"),        
    s.field( "tpg_channel_mask", self.id_list, default=[], doc="List of offline channels to be masked out from the TPHandler"),
    s.field( "tpset_min_latency_ticks", types.uint8, 3125000, doc="Latency introduced to allow for TPs to arrive and be reordered, default is 50 ms"),
    s.field( "tardy_tp_quiet_time_at_start_sec", types.int4, 10, doc="Amount of time that warning messages about tardy TPs will be suppressed at the start of a run, default is 10s"),
    s.field( "enable_raw_recording", types.flag, default=false, doc="Add queues and modules necessary for the record command"),
    s.field( "raw_recording_output_dir", types.path, default='.', doc="Output directory where recorded data is written to. Data for each link is written to a separate file"),
    s.field( "send_partial_fragments", types.flag, default=false, doc="Whether to send a partial fragment if one is available")
  ]),

};

stypes + snicreader + moo.oschema.sort_select(cs)
