module StephieVM
  STACK = Array(UInt32).new

  alias Program = Array(Slice(UInt8))

  enum Instruction : UInt8
    NOP    =   0
    CONST1 =   1
    CONST2 =   2
    CONST4 =   4
    ADD    =  10
    SUB    =  11
    MUL    =  12
    DIV    =  13
    MOD    =  14
    LT     =  20
    LTE    =  21
    GT     =  22
    GTE    =  23
    BRANCH =  30
    IF     =  31
    PRINT  =  40
    GNOP   = 255

    def self.from_value(value : UInt8)
      from_value?(value) || GNOP
    end
  end

  def self.run(program : Program, io : IO)
    stack = STACK
    stack.clear

    basic_block_ptr = 0

    while basic_block_ptr < program.size
      basic_block = program[basic_block_ptr]
      instructions = basic_block.each
      instructions.each do |instruction|
        case Instruction.from_value(instruction)
        when .nop?, .gnop?
        when .const1?
          # 1-byte const
          byte = read_byte(instructions)

          stack.push(byte)
        when .const2?
          # 2-byte const
          byte0 = read_byte(instructions)
          byte1 = read_byte(instructions)

          stack.push((byte0 << 8) | byte1)
        when .const4?
          # 4-byte const
          byte0 = read_byte(instructions)
          byte1 = read_byte(instructions)
          byte2 = read_byte(instructions)
          byte3 = read_byte(instructions)

          stack.push((byte0 << 24) | (byte1 << 16) | (byte2 << 8) | byte3)
        when .add?
          b = stack.pop
          a = stack.pop
          stack.push(a + b)
        when .sub?
          b = stack.pop
          a = stack.pop
          stack.push(a - b)
        when .mul?
          b = stack.pop
          a = stack.pop
          stack.push(a * b)
        when .div?
          divisor = stack.pop
          dividend = stack.pop
          stack.push(dividend // divisor)
        when .mod?
          b = stack.pop
          a = stack.pop
          stack.push(a % b)
        when .lt?
          b = stack.pop
          a = stack.pop

          if a < b
            stack.push(1_u32)
          else
            stack.push(0_u32)
          end
        when .lte?
          b = stack.pop
          a = stack.pop

          if a <= b
            stack.push(1_u32)
          else
            stack.push(0_u32)
          end
        when .gt?
          b = stack.pop
          a = stack.pop

          if a > b
            stack.push(1_u32)
          else
            stack.push(0_u32)
          end
        when .gte?
          b = stack.pop
          a = stack.pop

          if a >= b
            stack.push(1_u32)
          else
            stack.push(0_u32)
          end
        when .branch?
          basic_block_ptr = read_byte(instructions).to_i - 1
          break
        when .if?
          true_bb = read_byte(instructions)
          false_bb = read_byte(instructions)
          condition = stack.pop

          if condition != 0
            basic_block_ptr = true_bb.to_i - 1
          else
            basic_block_ptr = false_bb.to_i - 1
          end

          break
        when .print?
          io.print(stack.pop.chr)
        else
          raise "BUG: unhandled instruction #{instruction}"
        end
      end

      basic_block_ptr += 1
    end
  end

  def self.pretty_print(program : Program, io : IO = STDOUT)
    program.each_with_index do |basic_block, i|
      io.puts "BB #{i}"
      pretty_print(basic_block, io)
      io.puts
    end
  end

  def self.pretty_print(basic_block : Slice(UInt8), io : IO = STDOUT)
    instructions = basic_block.each
    instructions.each do |instruction|
      case Instruction.from_value(instruction)
      when .const1?
        # 1-byte const
        byte = read_byte(instructions)

        io.puts to_hexstr(byte, 1)
      when .const2?
        # 2-byte const
        byte0 = read_byte(instructions)
        byte1 = read_byte(instructions)

        io.puts to_hexstr((byte0 << 8) | byte1, 2)
      when .const4?
        # 4-byte const
        byte0 = read_byte(instructions)
        byte1 = read_byte(instructions)
        byte2 = read_byte(instructions)
        byte3 = read_byte(instructions)

        io.puts to_hexstr((byte0 << 24) | (byte1 << 16) | (byte2 << 8) | byte3, 4)
      when .branch?
        target_bb = read_byte(instructions)
        io.puts "BRANCH #{target_bb}"
      when .if?
        # IF
        true_bb = read_byte(instructions)
        false_bb = read_byte(instructions)
        io.puts "IF #{true_bb} #{false_bb}"
      else
        io.puts Instruction.from_value(instruction)
      end
    end
  end

  private def self.to_hexstr(int, size)
    "0x#{int.to_s(16).rjust(size * 2, '0')}"
  end

  private def self.read_byte(instructions : Iterator(UInt8))
    instructions.next.as(UInt8).to_u32
  end
end
