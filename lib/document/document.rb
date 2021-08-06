class Document
    attr_reader :raw, :lines, :version, :message

    def initialize(lines)
        @raw = lines.dup
        @lines = @raw.map { |line| line.chomp }.join
        @version = nil
        # Get critical values from document and reformat
        assign_values
        # Create line object dependant on tag
        @lines.map!.with_index do |line, line_no|
            begin
                params = [line, line_no, @version, @chars]
                case line[0, 3]
                when "ALI"; ALI.new(*params)
                when "BGM"; BGM.new(*params)
                when "CDI"; CDI.new(*params)
                when "CNT"; CNT.new(*params)
                when "CPS"; CPS.new(*params)
                when "DTM"; DTM.new(*params)
                when "FTX"; FTX.new(*params)
                when "GIN"; GIN.new(*params)
                when "GIR"; GIR.new(*params)
                when "IMD"; IMD.new(*params)
                when "INV"; INV.new(*params)
                when "LIN"; LIN.new(*params)
                when "LOC"; LOC.new(*params)
                when "MEA"; MEA.new(*params)
                when "MOA"; MOA.new(*params)
                when "NAD"; NAD.new(*params)
                when "PAC"; PAC.new(*params)
                when "PCI"; PCI.new(*params)
                when "PIA"; PIA.new(*params)
                when "PRI"; PRI.new(*params)
                when "QTY"; QTY.new(*params)
                when "RFF"; RFF.new(*params)
                when "TAX"; TAX.new(*params)
                when "UNA"; UNA.new(*params)
                when "UNB"; UNB.new(*params)
                when "UNH"; UNH.new(*params)
                when "UNS"; UNS.new(*params)
                when "UNT"; UNT.new(*params)
                when "UNZ"; UNZ.new(*params)
                else; Line.new(*params)
                end
            rescue => exception
                html_error(exception)
               #puts exception
               #puts exception.backtrace
                exit
            end
        end
    end

    def assign_values
        # Get punctuation values from UNA line
        una = lines[0, 3] == "UNA" ? lines[0, 9] : nil
        @chars = format_punctuation(una)
        # Split by segment terminator
        te = @chars.segment_terminator
        re = @chars.release_character
        @lines = @lines.split_with_release(te, re).map { |line| line + te }
        # Fix UNA segment
        @lines[0] = una if @lines[0][0, 3] == "UNA"
        # Save unedited lines
        @raw = @lines.dup
        # Get document information
        @lines.each_with_index do |line, line_no|
            if line[0, 3] == "UNH"
                unh = UNH.new(line, line_no, @version, @chars)
                @version = unh.message_version
                @message = unh.message_type
            end
        end
    end

    def format_punctuation(line = nil)
        unless line == nil
            return UNA.new(line, 0, @version).punctuation
        else
            return Punctuation.new(':', '+', '.', '?', '\'')
        end
    end

    def structure
        data = lookup_structure(@message.value, @version.ref)
        unless data == {}
            return Structure.new(self, data)
        end
    end

    def rows
        return @lines.map { |line| line.rows }
    end
    
    def debug
        @lines.each do |line|
            unless line.is_a?(UNA)
                line.table.each do |row|
                    puts row.join("\t, "), "\n"
                end
            end
        end
    end

    def html
        output = []
        @lines.each do |line|
            output << line.html
        end
        return output.join
    end

    def timeline
        times = []
        @lines.each do |line|
            if line.tag.value == "UNB"
                times << ["Preparation date time", line.time + " " + line.date]
            end
            if line.tag.value == "DTM"
                times << [line.qualifier.ref, line.interpret]
            end
        end
        return times.sort { |a, b| Time.parse(a[1]) <=> Time.parse(b[1]) }
    end
end