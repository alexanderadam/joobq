module JoobQ

  class Queue(T)
    getter redis : Redis::PooledClient = JoobQ.redis
    getter name : String
    getter total_workers : Int32
    getter workers : Array(Worker(T))
    getter jobs : String = T.to_s
    getter queue_size : Int32 = 100

    def initialize(@name : String, @total_workers : Int32)
      @dispatch_queue = Channel(Worker(T)).new(@total_workers)
      @workers = Array(Worker(T)).new(@total_workers)
      create_workers
    end

    def create_workers
      total_workers.times do |n|
        workers << Worker(T).new name, n
      end
    end

    def process
      workers.each &.run
    end

    def size
      redis.llen(name)
    end

    def stop!
      workers.all? &.stop
    end

    def running?
      workers.all? &.running?
    end

    def status
      case
      when !size.zero? then "Running"
      when size.zero? then "Done"
      else "Awaiting"
      end
    end

    def push(job : String)
      redis.lpush name, job
    end

    def running_workers
      workers.count &.running?
    end

    def clear
      redis.del name
    end
  end
end
