require 'parallel'

Parallel.each((0..32767)) do |i|
  h = 0
  1_000_000.times do |j|
    h += j
  end
  puts "Finished: #{i} #{h}"
  if i == 100
    puts "Found Working!!!"
    return
  end
end
