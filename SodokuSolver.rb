class SodokuSolver
  def initialize
    p "initialising"
    @possibles = Hash.new { |h,k| h[k] = (1..9).to_a }
    @actuals   = []
    @@square_map_indices = {1 => [1, 2, 3], 2 => [1, 2, 3], 3 => [1, 2, 3], 
                            4 => [4, 5, 6], 5 => [4, 5, 6], 6 => [4, 5, 6],
                            7 => [7, 8, 9], 8 => [7, 8, 9], 9 => [7, 8, 9]}
    @@square_map = Hash[(1..9).zip([1,1,1,2,2,2,3,3,3])]
    @@values = (1..9).to_a
    (0..8).to_a.each { |i| @actuals[i] = Array.new(9, 0) }
    init_partials()
  end
  
  def init_partials()
    tmp = {1=>1, 2=>4, 3=>7} 
    @partials = {}
    @squares = {}
    [1,2,3].each { |sq_x_idx|
      [1,2,3].each { |sq_y_idx|
        possible_x = @@square_map_indices[tmp[sq_x_idx]]
        possible_y = @@square_map_indices[tmp[sq_y_idx]]
        @partials[[sq_x_idx,sq_y_idx]] = {}
        (1..9).each {|v| @partials[[sq_x_idx,sq_y_idx]][v] = [possible_x.dup,possible_y.dup] }
        possible_locations = [] 
        possible_x.each { |x| possible_y.each {|y| possible_locations += [[x,y]] }}
        @squares[[sq_x_idx,sq_y_idx]] = {}
        (1..9).each { |v| @squares[[sq_x_idx,sq_y_idx]][v] = possible_locations.dup }
      }
    }
  end
  
  def solve(filename)
    data = read_initial_solution(filename)
    data.each { |x,y,value| 
      solve_cell(x,y,value)
    }
    #p @squares.inspect
    #print_possibles()
    print_actuals()
    #p @partials.inspect
    p "done solving"
    return [@partials,@squares]
  end
  
  def solve_cell(x,y,value)
    #p "solving #{x},#{y} to #{value}"
    solve_actual(x,y,value)
    solve_possibles(x,y,value)
    solve_squares(x,y,value)
    solve_partials(x,y,value)
    check_partials()
    check_squares()
    check_possibles()
  end
  
  def solve_cell_partial(x,y,value)
    #p "partial solution #{x},#{y},#{value}"
    ruled_out_possibilities = 
      if (x.is_a?(Array))
        tmp = (1..9).to_a - x
        tmp.zip([y]*tmp.length)
      else
        tmp = (1..9).to_a - y
        ([x]*tmp.length).zip(tmp)
      end
    ruled_out_possibilities.each { |x,y| @possibles[[x,y]].delete(value) }
    sq_x_idx, sq_y_idx = idx_to_square_idx(x,y)
    [1,2,3].each { |sq_pos| 
      @squares[[sq_x_idx,sq_pos]][value] -= ruled_out_possibilities
      @squares[[sq_pos,sq_y_idx]][value] -= ruled_out_possibilities
    }
  end
  
  def solve_actual(x,y,value)
    @actuals[x-1][y-1] = value
    @possibles[[x,y]] = []
    @squares[[@@square_map[x],@@square_map[y]]][value] = []
  end
  
  def solve_possibles(x,y,value)
    (1..9).to_a.each { |pos|
      @possibles[[x,pos]].delete(value) 
      @possibles[[pos,y]].delete(value) 
      next if (x<0 || y<0)
      @@square_map_indices[x].each { |x_idx| 
        @@square_map_indices[y].each { |y_idx|
          @possibles[[x_idx,y_idx]].delete(value)
        }
      }
    }
  end
  
  def idx_to_square_idx(x,y)
    return [@@square_map[x], @@square_map[y]]
  end
  
  def solve_squares(x,y,value)
    sq_x_idx, sq_y_idx = idx_to_square_idx(x,y)
    # solve in the current square
    @squares[[sq_x_idx,sq_y_idx]].each {|v,possible_locations|
      possible_locations.delete([x,y])
    }
    # solve in adjacent squares
    [1,2,3].each { |sq_pos| 
      @squares[[sq_x_idx,sq_pos]][value].delete_if { |x1,y1| x1==x }
      @squares[[sq_pos,sq_y_idx]][value].delete_if { |x1,y1| y1==y }
    }
    # check for two cell exclusivity
    @squares.each { |pos,square|
      @@values.each { |i| ((i+1)..9).to_a.each { |j|
        if square[i].size == 2 && square[j].size == 2 && square[i]==square[j]
          (@@values - [i,j]).each { |k| square[k] -= square[i] }
        end
      }}
    }
  end
  
  def solve_partials(x,y,value)
    @partials.each { |key, partial|
      square = @squares[key]
      @@values.each { |value|
        possible_x = square[value].map { |x1,y1| x1 }.uniq 
        possible_y = square[value].map { |x1,y1| y1 }.uniq
        partial[value] = [possible_x, possible_y]
      }
    }
  end
  
  def check_possibles()
    (1..9).to_a.each {|x| (1..9).to_a.each {|y| 
      solve_cell(x,y,@possibles[[x,y]].first) if @possibles[[x,y]].size == 1
    }}
  end
  
  def check_partials()
    @partials.each { |(sq_x,sq_y),partial|
      partial.each { |v,(row_pos,col_pos)|
        if (row_pos.size == 1 && col_pos.size == 1)
          solve_cell(row_pos.first, col_pos.first,v)
        elsif row_pos.size == 1
          solve_cell_partial(row_pos.first,col_pos,v)
          row_pos.drop_while {true}
        elsif col_pos.size == 1
          solve_cell_partial(row_pos,col_pos.first,v)
          col_pos.drop_while {true}
        end
      }
    }
  end
  
  def check_squares()
    @squares.each { |(sq_x,sq_y),square|
      
      square.each { |value,possible_locations|
        if (possible_locations.size == 1)
          solve_cell(*(possible_locations.first+[value]))
        end
      }
    }
  end
  
  def read_initial_solution(filename)
    return read_single_line(filename) unless File.exist?(filename)
    data = IO.readlines(filename)
    if data.match(/\,/)
      return data.map!{|l| l.split(',').map {|t| t.to_i}}
    else
      read_single_line(data)
    end	
  end
  
  def read_single_line(data)
    idx = -1;
    data.scan(/./).map { |i| idx+=1; [(idx - idx % 9) / 9 + 1, idx % 9 + 1,i.to_i]}.select{ |x| x[2] != 0 }
  end
  
  def print_possibles()
    @possibles.each {|k,v| 
      p "#{k} => #{v}"
    }
  end
  
  def print_actuals()
    @actuals.each_with_index {|row,row_idx|
      tmp = row.join(' | ').split(' ')
      tmp[5], tmp[11] = ' || ', ' || '
      p tmp.join(' ')
      p "="*39 if [2,5].member?(row_idx)
    }
  end
end
