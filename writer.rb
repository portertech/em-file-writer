require "eventmachine"

def write(file_path, data, chunk_size=65536)
  file = ::File.open(file_path, "w")

  pos = 0

  if data.kind_of?(IO)
    io = data
  else
    io = StringIO::new(data)
  end

  writer = Proc::new do
    begin
      chunk = io.read(chunk_size)
      file.write(chunk)
    rescue Errno::EBADF
      file = ::File.open(file_path, "w")
      file.seek(pos)
      redo
    end

    pos = file.pos

    if io.eof?
      yield pos if block_given?
    else
      EM::next_tick(&writer)
    end
  end

  writer.call
end

EM.run do
  pid = Process.pid
  file_path = File.join("/tmp", "stringio_#{pid}.txt")
  write(file_path, "foobar") do
    file_path = File.join("/tmp", "sherlock_#{pid}.txt")
    data_path = File.join(File.dirname(__FILE__), "sherlock.txt")
    data = File.open(data_path, "r")
    write(file_path, data) do
      puts "done!"
      EM.stop
    end
  end
end
