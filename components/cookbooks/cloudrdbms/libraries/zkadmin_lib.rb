#to run this class you need to export PATH=${ZOOKEEPER_HOME}/bin:${PATH}
#otherwise, you need to hardcode the zk path
class ZKAdmin
  #constants
  PARTICIPANT = 'participant'
  OBSERVER = 'observer'

  STATIC_CONFIG_FILE = 'zoo.cfg'
  MYID_FILE = 'myid'

  #need to create a data/conf directory in the first place
  DEFAULT_CONFIG_DIR = '/app/zookeeper/current/conf'
  DEFAULT_DATA_DIR = '/app/zookeeper/current/data'

  DEFAULT_DATA_PORT = 2888
  DEFAULT_ELECTION_PORT = 3888
  DEFAULT_CLIENT_PORT = 2181
  DEFAULT_SYNC_LIMIT = 10
  DEFAULT_TICK_TIME = 8000
  DEFAULT_INIT_LIMIT = 10
  
  #add the other attributes, etc. if needed
  #this class is immutable
  class ZKPeer
    attr_reader :id, :address, :role, :dataPort, :electionPort, :clientPort
    def initialize(id, address, role = PARTICIPANT, dataPort = DEFAULT_DATA_PORT,
      electionPort = DEFAULT_ELECTION_PORT, clientPort = DEFAULT_CLIENT_PORT)
      @id = id
      @address = address
      @role = role
      @dataPort = dataPort
      @electionPort = electionPort
      @clientPort = clientPort
    end

    def toDynamicEntry()
      #note that the cluster address and the client address are the same in our case
      return "server.#{@id}=#{@address}:#{@dataPort}:#{@electionPort}:#{@role};#{@address}:#{@clientPort}"
    end

    #clone all attributes except the role
    def clone(newRole)
      return ZKPeer.new(@id, @address, newRole, @dataPort, @electionPort, @clientPort)
    end
  end

  #refer to ZKPeer for itself
  attr_accessor :selfEntry
  #add more attributes if needed
  attr_reader :configDir, :dataDir, :initLimit, :syncLimit, :tickTime

  def initialize(id, address, role = PARTICIPANT,  configDir = DEFAULT_CONFIG_DIR, dataDir = DEFAULT_DATA_DIR,
    dataPort = DEFAULT_DATA_PORT, electionPort = DEFAULT_ELECTION_PORT, clientPort = DEFAULT_CLIENT_PORT,
    initLimit = DEFAULT_INIT_LIMIT, syncLimit = DEFAULT_SYNC_LIMIT, tickTime = DEFAULT_TICK_TIME)
    @selfEntry = ZKPeer.new(id, address, role, dataPort, electionPort, clientPort)
    @configDir = configDir
    @dataDir = dataDir
    @initLimit = initLimit
    @syncLimit = syncLimit
    @tickTime = tickTime
  end
  
  def initialize(selfZkEntry, configDir = DEFAULT_CONFIG_DIR, dataDir = DEFAULT_DATA_DIR,
    dataPort = DEFAULT_DATA_PORT, electionPort = DEFAULT_ELECTION_PORT, clientPort = DEFAULT_CLIENT_PORT,
    initLimit = DEFAULT_INIT_LIMIT, syncLimit = DEFAULT_SYNC_LIMIT, tickTime = DEFAULT_TICK_TIME)
    @selfEntry = selfZkEntry
    @configDir = configDir
    @dataDir = dataDir
    @initLimit = initLimit
    @syncLimit = syncLimit
    @tickTime = tickTime
  end

  def getLocalZKConn()
    return "127.0.0.1:#{@selfEntry.clientPort}";
  end

  def getConfigFilePath()
    return "#{@configDir}/#{STATIC_CONFIG_FILE}"
  end

  def getMyIDFilePath()
    return "#{@dataDir}/#{MYID_FILE}"
  end

  #peers is an array of ZKPeer instances including itself, if itself is not in the list,
  #add itself in first
  #we don't use chef erb file for the benefit of flexibility and separation
  def config(peers = [])
    if(peers.none? { |p| p.id == @selfEntry.id } )
      peers << @selfEntry
    end

    #better to not touch it after the initial setup
    open("#{getConfigFilePath()}", 'w') { |file|
      #hardcode it as false excluding other possible value
      file << "standaloneEnabled=false\n"
      file << "dataDir=#{@dataDir}\n"
      file << "syncLimit=#{@syncLimit}\n"
      file << "tickTime=#{@tickTime}\n"
      file << "initLimit=#{@initLimit}\n"
      peers.each { |peer|
        file << peer.toDynamicEntry() + "\n"
      }
    }

    #write myid file
    open("#{getMyIDFilePath()}", 'w') { |file|
      file << "#{@selfEntry.id}"
    }
  end

  ###########################################################
  #we may need to add loadConfig() that load existing config
  #from config files ######, so far we are fine
  ###########################################################

  def start()
    %x( zkServer.sh --config  "#{@configDir}"  start )
    if $?.exitstatus != 0
      raise RuntimeError, "CloudRDBMS node #{@address} failed to start zk server"
    end
  end

  def stop()
    %x( zkServer.sh --config  "#{@configDir}"  stop )
    if $?.exitstatus != 0
      raise RuntimeError, "CloudRDBMS node #{@address} failed to stop zk server"
    end
  end

  def restart()
    #the restart subcommand of zkServer.sh does not work well with parameter --config
    #as an alternative, we use stop and then start
    stop()
    #sleep 4 seconds, zookeeper server socket needs time to close
    sleep(4)
    start()
  end

  def promote()
    promotedSelf = @selfEntry.clone(PARTICIPANT)
    %x( zkCli.sh -server  "#{getLocalZKConn()}" reconfig -add "#{promotedSelf.toDynamicEntry()}" )
    if $?.exitstatus != 0
      raise RuntimeError, "CloudRDBMS node #{@selfEntry.address} failed to promote selfEntry as participant"
    end
    @selfEntry = promotedSelf
  end

  def demote()
    demotedSelf = @selfEntry.clone(OBSERVER)
    %x( zkCli.sh -server  "#{getLocalZKConn()}" reconfig -add "#{demotedSelf.toDynamicEntry()}" )
    if $?.exitstatus != 0
      raise RuntimeError, "CloudRDBMS node #{@selfEntry.address} failed to demote selfEntry to observer"
    end
    @selfEntry = demotedSelf
  end

  #need to check
  def add()
    %x( zkCli.sh -server  "#{getLocalZKConn()}" reconfig -add "#{@selfEntry.toDynamicEntry()}" )
    if $?.exitstatus != 0
      raise RuntimeError, "CloudRDBMS node #{@selfEntry.address} failed to add this zk server to the cluster"
    end
  end

  def remove()
    %x( zkCli.sh -server  "#{getLocalZKConn()}" reconfig -remove "#{@selfEntry.toDynamicEntry()}" )
    if $?.exitstatus != 0
      raise RuntimeError, "CloudRDBMS node #{@selfEntry.address} failed to remove itself from the cluster"
    end
  end

  #test if the zk server has started/configured before
  #if it has configured before, just use the existing setting
  #it is not in use so far, but leave here
  def isNew()
    if !File.file?(getConfigFilePath()) || ! File.file?(getMyIDFilePath())
      return true
    end
    return false
  end

  #test example, use fake mysql server_id
  #zk1entry = ZKAdmin::ZKPeer.new(1, "127.0.0.1", 'participant')
  #zk2entry = ZKAdmin::ZKPeer.new(2, "127.0.0.1", 'participant')
  
  #zk1=ZKAdmin.new(zk1entry) or
  #zk1=ZKAdmin.new(1, "127.0.0.1", 'participant') or
  #zk2=ZKAdmin.new(2, "127.0.0.1", 'participant', "/tmp/zookeeper-1/conf", "/tmp/zookeeper-1/data", 3001, 3002, 3003)
  
  #zk1.config([zk2entry, zk1entry])
  #zk2.config([zk2entry, zk1entry])
  #zk1.start/stop/restart/promote/demote
  #zk2.start/stop/restart/promote/demote
end
