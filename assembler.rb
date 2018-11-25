class HackBasicAssembler
  @toTranslate
  @code
  @parser
  @smblTable

  def initialize(str)
    @toTranslate = str
    @code = HackCode.new
    @parser = HackParser.new
    @smblTable = HackSymbolTable.new
  end

  def firstPhase
    row = 0
    result = ""
    @toTranslate.each_line do |line|
      relevant = line.split("//")[0].strip
      next if relevant.empty?
      if relevant.include? "("
        label = relevant[1..-2]
        @smblTable.addLabel(label, row.to_s)
        next
      end
      row += 1
      result = result + relevant + "\n"
    end
    @toTranslate = result
  end

  def secondPhase
    result = ""
    @toTranslate.each_line do |line|
      if(line[0] == "@")
        aInstruction = "0000000000000000"
        toDecode = line[1..-2]
        ind = (toDecode =~ /\D/)
        unless ind.nil?
          smbl = @smblTable.getSymbol(toDecode)
          if smbl.nil?
            smbl = @smblTable.addSymbol(toDecode)
          end
          toDecode = smbl
        end
        decoded = @code.ACode(toDecode)
        aInstruction[(-decoded.length)..-1] = decoded
        result += aInstruction + "\n"
        next
      end
      @parser.setStr line[0..-2]
      dest = @parser.getDest
      jmp = @parser.getJump
      comp = @parser.getComp
      decodedDest = @code.CDest(dest)
      decodedJmp = @code.CJump(jmp)
      decodedComp = @code.CComp(comp)
      cInstruction = "111" + decodedComp + decodedDest + decodedJmp
      result += cInstruction + "\n"
    end
    @toTranslate = result
  end

  def getStr
    @toTranslate
  end

  class HackParser
    @str

    def initialize
    end

    def setStr(str)
      @str = str
    end

    def getDest
      return nil if !@str.include? "="
      strspl = @str.split("=")
      @str = strspl[1]
      strspl[0]
    end

    def getJump
      return nil if !@str.include? ";"
      strspl = @str.split(";")
      @str = strspl[0]
      strspl[1]
    end

    def getComp
      @str
    end

  end

  class HackCode
    @@CCompTable
    @@CDestTable    
    @@CJumpTable

    def initialize
      @@CCompTable = {"0" => "0101010",
                    "1" => "0111111",
                   "-1" => "0111010",
                    "D" => "0001100",
                    "A" => "0110000",
                    "M" => "1110000",
                   "!D" => "0001101",
                   "!A" => "0110001",
                   "!M" => "1110001",
                   "-D" => "0001111",
                   "-A" => "0110011",
                   "-M" => "1110011",
                  "D+1" => "0011111",
                  "A+1" => "0110111",
                  "M+1" => "1110111",
                  "D-1" => "0001110",
                  "A-1" => "0110010",
                  "M-1" => "1110010",
                  "D+A" => "0000010",
                  "D+M" => "1000010",
                  "D-A" => "0010011",
                  "D-M" => "1010011",
                  "A-D" => "0000111",
                  "M-D" => "1000111",
                  "D&A" => "0000000",
                  "D&M" => "1000000",
                  "D|A" => "0010101",
                  "D|M" => "1010101"}

      @@CDestTable = {nil => "000",
                    "M" => "001",
                    "D" => "010",
                   "MD" => "011",
                    "A" => "100",
                   "AM" => "101",
                   "AD" => "110",
                  "AMD" => "111"}

      @@CJumpTable = {nil  => "000",
                   "JGT" => "001",
                   "JEQ" => "010",
                   "JGE" => "011",
                   "JLT" => "100",
                   "JNE" => "101",
                   "JLE" => "110",
                   "JMP" => "111"}
    end

    def CComp(str)
      @@CCompTable[str]
    end

    def CDest(str)
      @@CDestTable[str]
    end

    def CJump(str)
      @@CJumpTable[str]
    end

    def ACode(str)
      str.to_i.to_s(2)
    end
  end

  class HackSymbolTable
    @smbTable
    @symbolCount

    def initialize
      @smbTable = {"SP" => "0",
                "LCL" => "1",
                "ARG" => "2",
               "THIS" => "3",
               "THAT" => "4",
                 "R0" => "0",
                 "R1" => "1",
                 "R2" => "2",
                 "R3" => "3",
                 "R4" => "4",
                 "R5" => "5",
                 "R6" => "6",
                 "R7" => "7",
                 "R8" => "8",
                 "R9" => "9",
                 "R10" => "10",
                 "R11" => "11",
                 "R12" => "12",
                 "R13" => "13",
                 "R14" => "14",
                 "R15" => "15",
              "SCREEN" => "16384",
                 "KBD" => "24576"}
      @symbolCount = 16    
    end

    def addLabel(label, row)
      @smbTable[label] = row
    end

    def addSymbol(smbl)
      @smbTable[smbl] = @symbolCount.to_s
      @symbolCount += 1
      getSymbol(smbl)
    end

    def getSymbol(smbl)
      @smbTable[smbl.to_s]
    end
  end
end

def main
  continue = 'y'
  while continue.eql? 'y'
	print 'Please specify .asm absolute file path to be opened: '
	fiPath = gets
	fiPath.chomp
	fi = File.new(fiPath)
	toTranslate = fi.read
	hba = HackBasicAssembler.new(toTranslate)
	hba.firstPhase
	translated = hba.secondPhase
	print 'Please specify .hack absolute file path to be saved: '
	foPath = gets
	foPath.chomp
	fo = File.new(foPath, File::CREAT|File::TRUNC|File::RDWR, 0644)
	fo.write(translated)
	fo.flush
	print 'Would you like to continue? (y/n): '
	continue = gets
	continue.chomp
  end
end

main