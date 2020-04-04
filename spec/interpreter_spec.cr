require "../src/interpreter"
require "spec"

private def bb(*instructions : Symbol | Int32 | Char) : Slice(UInt8)
  bb = Slice(UInt8).new(instructions.size, 0)
  instructions.each_with_index do |instruction, i|
    case instruction
    when Symbol
      bb[i] = StephieVM::Instruction.parse(instruction.to_s).to_u8
    when Int
      bb[i] = instruction.to_u8
    when Char
      bb[i] = instruction.ord.to_u8
    end
  end
  bb
end

private def pretty_print(arg)
  io = IO::Memory.new
  StephieVM.pretty_print(arg, io)
  io.to_s.chomp
end

private def exec(prog)
  io = IO::Memory.new
  StephieVM.run(prog, io)
  io.to_s
end

describe StephieVM do
  it "pretty prints basic blocks" do
    bb = bb(
      :nop,
      :const1, 1,
      :const4, 0x08, 0x00, 0x81, 0x35,
      :add
    )

    pretty_print(bb).should eq(<<-EOF)
      NOP
      0x01
      0x08008135
      ADD
      EOF
  end

  it "pretty prints programs" do
    program = [
      bb(
        :const1, 1,
        :const1, 2,
        :add,
        :const1, 2,
        :lt,
        :if, 1, 2
      ),
      bb(
        :const1, 't',
        :print
      ),
      bb(
        :const1, 'f',
        :print
      ),
    ]

    pretty_print(program).should eq(<<-EOF)
      BB 0
      0x01
      0x02
      ADD
      0x02
      LT
      IF 1 2

      BB 1
      0x74
      PRINT

      BB 2
      0x66
      PRINT

      EOF
  end

  it "runs programs" do
    program = [
      bb(
        :const1, 1,
        :const1, 2,
        :add,
        :const1, 2,
        :lt,
        :if, 1, 2
      ),
      bb(
        :const1, 't',
        :print
      ),
      bb(
        :const1, 'f',
        :print
      ),
    ]

    exec(program).should eq("f")
  end
end
