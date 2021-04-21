GRID = [
  [:*,8,:-,1],
  [4,:*,11,:*],
  [:+,4,:-,18],
  [22,:-,9,:*],
]

DIRS = {
  'north' => [0,-1],
  'south' => [0,1],
  'east' => [1,0],
  'west' => [-1,0],
}

END_SQUARES = [[3,0],[0,3]]
GOAL = 30

def bfs
  # [path_followed, weight, x, y]
  start = [[], 22, 0, 3]
  paths = [start]
  steps = 0
  while paths.length > 0 do
    steps += 2
    new_paths = []
    puts "Steps: #{steps} Paths: #{paths.count}"
    # puts "Paths: #{paths}"
    paths.each do |path|
      followed, weight, x, y = path
      DIRS.each do |dir_a, delta_a|
        x_a, y_a = delta_a
        new_x = x + x_a
        new_y = y + y_a
        op = new_y.between?(0, 3) && new_x.between?(0, 3) ? GRID[new_y][new_x] : nil
        op = nil if END_SQUARES.include? [new_x, new_y]
        if op
          DIRS.each do |dir_b, delta_b|
            x_b, y_b = delta_b
            new_x = x + x_a + x_b
            new_y = y + y_a + y_b
            num = new_y.between?(0, 3) && new_x.between?(0, 3) ? GRID[new_y][new_x] : nil
            if op && num && !(new_x == 0 && new_y == 3)
              begin
                new_weight = weight.__send__(op, num)
              rescue => e
                require 'pry'
                binding.pry
                raise e
              end
              if new_weight > 0
                new_followed = followed + [dir_a, dir_b]
                if new_x == 3 && new_y == 0
                  if new_weight == 30
                    puts "Found!!!"
                    puts "Path: #{new_followed}, #{weight}, #{steps}"
                    return
                  end
                else
                  new_paths << [new_followed, new_weight, new_x, new_y]
                end
              end
            end
          end
        end
      end
    end
    if steps > 16
      raise "Too many steps!!!"
    end
    paths = new_paths
  end
end

bfs
