# /un_edifact/
#   lists/ "data csv lists"                   (e.g. service_segments.csv)
#   uncl/  "coded data reference"             (e.g. UNCL_D00A.json)
#   edcd/  "composite element specs"          (e.g. EDCD_D97A.json)  
#   eded/  "element list with name/desc/repr" (e.g. EDED_D97A.json)  
#   edmd/  "message structure"                (e.g. EDMD_APERAK_D97A.json)
#   edsd/  "segment specs"                    (e.g. EDSD_D97A.json)
#   ss/    "service segment specs"            (e.g. SS_40000.json)
#   sc/    "composite service element specs"  (e.g. SC_40000.json)
#   se/    "service element specs"            (e.g. SE_40000.json)
#   unas/  "UNA segment specs"                (e.g. UNAS.json)

FALLBACK_VERSION = "D97A"
DEFAULT_CODE_LIST = "UNCL"
DEFAULT_CODE_LIST_PATH = "/agencies/un_edifact/uncl/UNCL_D20B.json"
DEFAULT_CACHE = {
    "un_edifact" => {
        "edcd" => {}, "eded" => {}, "edmd" => {}, "edsd" => {},
        "uncl" => {}, "ss" => {}, "sc" => {}, "se" => {},
        "unas" => {}, "lists" => {}
    }
}

AGENCY_CODELIST_MAP = {
#   3055   => [name, path],
    DEFAULT_CODE_LIST => [DEFAULT_CODE_LIST.downcase, DEFAULT_CODE_LIST_PATH],
    "9"    => ["eancom", "/agencies/eancom/cl.json"],
    "10"   => ["odette", "/agencies/odette/cl.json"],
    "20"   => ["bic", "/agencies/bic/cl.json"],
    "166"  => ["nmfca", "/agencies/nmfca/cl.json"],
    "306"  => ["smdg", "/agencies/smdg/cl.json"],
    "321"  => ["edigas", "/agencies/edigas/cl/CL_4.json"],
    "ZEW"  => ["edigas", "/agencies/edigas/cl/CL_4.json"],
    "6346" => ["iso_6346", "/agencies/smdg/iso_6346.json"],
    "IATA" => ["iata", "/agencies/iata/cl.json"],
}

class Dictionary
    attr_reader :read_count

    def initialize(dir = DATA_PATH)
        @dir = dir
        @read_count = 0
        @code_lists_used = []
        @cache = DEFAULT_CACHE
    end

    def code_lists_used_count
        return @code_lists_used.length
    end

    def code_lists_used
        list, splits = [], {}
        begin
            @code_lists_used.each do |name, qualifier|
                if qualifier == nil
                    list << name
                else
                    splits[name] = [] unless splits.key?(name)
                    splits[name] << qualifier
                end
            end
            for key, qualifiers in splits do
                if qualifiers.length < 5
                    list << "#{key} #{qualifiers.join(", ")}"
                else
                    list << "#{key} (#{qualifiers.length})"
                end
            end
            return list
        rescue
            return []
        end
    end

    def add_code_list_used(name, qualifier = nil)
        return if name == DEFAULT_CODE_LIST
        @code_lists_used << [name, qualifier]
        @code_lists_used = @code_lists_used.uniq
    end

    def data_list_lookup(name, dir = @dir)
        path = "#{dir}/lists/#{name}.csv"
        return [] unless File.file?(path)
        return File.readlines(path)
    end

    def code_list_lookup(agency, qualifier = nil, code = nil)
        if AGENCY_CODELIST_MAP.key?(agency)
            name, path = AGENCY_CODELIST_MAP[agency]
            data = retrieve_hash(name, path)
            if qualifier == nil
                add_code_list_used(name.unkey.upcase)
                return data
            end
            puts "AGENCY=#{agency}; QUALIFIER=#{qualifier}; CODE=#{code}"
            unless data.dig(qualifier, code).blank?
                add_code_list_used(name.unkey.upcase, qualifier)
                return data[qualifier][code]
            else
                unless agency == DEFAULT_CODE_LIST
                    code_list_lookup(DEFAULT_CODE_LIST, qualifier, code)
                end
            end
        end
        return {}
    end

    def has_version?(version)
        for datatype in ["uncl", "edcd", "eded"] do
            basename = "#{datatype.upcase}_#{version}"
            path = "/agencies/un_edifact/#{datatype}/#{basename}.json"
            return false unless File.file?(@dir + path)
        end
        return true
    end

    def is_service_segment?(value, subset = nil)
        subset = "un_edifact" if subset.blank?
        subset = "un_edifact" if subset == "EDIFICE" # TODO: implement EDIFICE
        subset = "un_edifact" if subset == "EANCOM"  # TODO: implement EANCOM
        params = ["service_segments", subset.downcase]
        return retrieve_csv_column(*params).include?(value)
    end

    def is_service_element?(value, subset = nil)
        subset = "un_edifact" if subset.blank?
        subset = "un_edifact" if subset == "EDIFICE" # TODO: implement EDIFICE
        subset = "un_edifact" if subset == "EANCOM"  # TODO: implement EANCOM
        params = ["service_simple_elements", subset.downcase]
        return retrieve_csv_column(*params).include?(value)
    end

    def is_service_composite?(value, subset = nil)
        subset = "un_edifact" if subset.blank?
        subset = "un_edifact" if subset == "EDIFICE" # TODO: implement EDIFICE
        subset = "un_edifact" if subset == "EANCOM"  # TODO: implement EANCOM
        params = ["service_composite_elements", subset.downcase]
        return retrieve_csv_column(*params).include?(value)
    end

    def coded_data_reference(code, value, version = nil, subset = nil)
        version = FALLBACK_VERSION if version == nil
        if subset.blank? or (subset == "un_edifact")
            data = retrieve_un_edifact_data("UNCL", version)
        else
            case subset
            when "UNICORN"; params = ["CL", "UNICORN", "22"]
            else; return coded_data_reference(code, value, version)
            end
            data = retrieve_subset_data(*params)
            # Default to no subset if data is blank
            if data.dig(code, value).blank?
                return coded_data_reference(code, value, version)
            end
        end
        return {} if data.dig(code, value) == nil
        return data[code][value]
    end

    def element_specification(code, version = nil, subset = nil)
        version = FALLBACK_VERSION if version == nil
        if subset.blank? or (subset == "un_edifact")
            data = retrieve_un_edifact_data("EDED", version)
        else
            case subset
            when "UNICORN"; params = ["ED", "UNICORN", "22"]
            else; return element_specification(code, version)
            end
            data = retrieve_subset_data(*params)
        end
        return data.key?(code) ? data[code] : {}
    end

    def service_element_specification(code, version = nil, subset = nil)
        version = "40000" if version == nil
        if subset.blank? or (subset == "un_edifact")
            data = retrieve_un_edifact_data("SE", version)
        else
            case subset
            when "UNICORN"; params = ["SE", "UNICORN", "22"]
            else; return service_element_specification(code, version)
            end
            data = retrieve_subset_data(*params)
        end
        return data.key?(code) ? data[code] : {}
    end

    def composite_specification(code, version = nil, subset = nil)
        version = FALLBACK_VERSION if version == nil
        if subset.blank? or (subset == "un_edifact")
            data = retrieve_un_edifact_data("EDCD", version)
        else
            case subset
            when "UNICORN"; params = ["CD", "UNICORN", "22"]
            else; return composite_specification(code, version)
            end
            data = retrieve_subset_data(*params)
        end
        return data.key?(code) ? data[code] : {}
    end

    def service_composite_specification(code, version = "40000", subset = nil)
        version = "40000" if version == nil
        if subset.blank? or (subset == "un_edifact")
            data = retrieve_un_edifact_data("SC", version)
        else
            case subset
            when "UNICORN"; params = ["SC", "UNICORN", "22"]
            else; return service_composite_specification(code, version)
            end
            data = retrieve_subset_data(*params)
        end
        return data.key?(code) ? data[code] : {}
    end

    def segment_specification(tag, version, subset = "un_edifact")
        return {} if version == nil
        if subset.blank? or (subset == "un_edifact")
            data = retrieve_un_edifact_data("EDSD", version)
        else
            case subset
            when "UNICORN"; params = ["SD", "UNICORN", "22"]
            else; return segment_specification(tag, version)
            end
            data = retrieve_subset_data(*params)
            # Default to no subset if data is blank
            if data.dig(tag).blank?
                return segment_specification(tag, version)
            end
        end
        return data.key?(tag) ? data[tag] : {}
    end

    def service_segment_specification(tag, version = "40000", subset = nil)
        return self.una_segment_specification(version) if tag == 'UNA'
        version = "40000" if version == nil
        if subset.blank? or (subset == "un_edifact")
            data = retrieve_un_edifact_data("SS", version)
        else
            case subset
            when "UNICORN"; params = ["SS", "UNICORN", "22"]
            else; return service_segment_specification(tag, version)
            end
            data = retrieve_subset_data(*params)
            # Default to no subset if data is blank
            if data.dig(tag).blank?
                return service_segment_specification(tag, version)
            end
        end
        return data.key?(tag) ? data[tag] : {}
    end

    def una_segment_specification(version = "40000")
        return {} if version == nil
        data = retrieve_un_edifact_data("UNAS", version)
        return data.key?("UNA") ? data["UNA"] : {}
    end

    def message_structure_specification(message, version = nil, subset = nil)
        return {} if version == nil
        if subset.blank? or (subset == "un_edifact")
            data = retrieve_un_edifact_data("EDMD", version, message)
        else
            case subset
            when "UNICORN"; params = ["MD", "UNICORN", "22", message]
            when "EDIFICE"; params = ["MD", "EDIFICE", "D10A", message]
            else; return message_structure_specification(message, version)
            end
            data = retrieve_subset_data(*params)
        end
        return data
    end

    def retrieve_subset_data(datatype, subset, version, message = nil)
        # Ensure correct casing on all strings
        datatype = datatype.downcase
        version = version.upcase unless version == nil
        message = message.upcase unless message == nil
        #
        @cache[subset] = {} unless @cache.key?(subset)
        if @cache.dig(subset, datatype).blank?
            @cache[subset] = { datatype => {} }
        end
        @cache[subset][datatype].tap do |entry|
            # Return cached version if it exists
            key = message.blank? ? version : message + "_" + version
            return entry[key] if entry.key?(key)
            # Otherwise load, store, and return
            basename = "#{datatype.upcase}_#{key}"
            path = "/agencies/#{subset.downcase}/#{datatype}/#{basename}.json"
            data = load_json(path)
            entry[key] = data unless data.blank?
            return data
        end
    end

    def retrieve_un_edifact_data(datatype, version, message = nil)
        # Ensure correct casing on all strings
        datatype = datatype.downcase
        version = version.upcase unless version == nil
        message = message.upcase unless message == nil
        # In context of the correct entry in the cache
        @cache["un_edifact"][datatype].tap do |entry|
            # Return cached version if it exists
            key = message.blank? ? version : message + "_" + version
            return entry[key] if entry.key?(key)
            # Otherwise load, store, and return
            basename = "#{datatype.upcase}_#{key}"
            path = "/agencies/un_edifact/#{datatype}/#{basename}.json"
            data = load_json(path)
            if data.blank? and (version != FALLBACK_VERSION)
                data = retrieve_un_edifact_data(
                    datatype, FALLBACK_VERSION, message
                )
            end
            entry[key] = data
            return data
        end
    end

    def retrieve_hash(key, path)
        # Use cached version if it exists (and not only "lists")
        if @cache.key?(key) && (@cache[key].keys != ["lists"])
            return @cache[key]
        end
        # Otherwise load, and store
        data = load_json(path)
        return {} if data == {}
        @cache[key] = data
        return data
    end

    def retrieve_csv_column(file_name, subset = "un_edifact", column = 0)
        # In context of the correct entry in the cache
        @cache[subset] = {} unless @cache.key?(subset)
        @cache[subset]["lists"] = {} if @cache.dig(subset, "lists").blank?
        @cache[subset]["lists"].tap do |entry|
            if entry.key?(file_name)
                csv = entry[file_name]
            else
                # Otherwise load, and store
                path = "#{@dir}/agencies/#{subset}/lists/#{file_name}.csv"
                return [] unless File.file?(path)
                csv = CSV.read(path)
                entry[file_name] = csv
                # Increment dictionary read count
                # puts file_name
                @read_count += 1
            end
            # Return given column of csv
            return csv.map { |line| line[column] }
        end
    end

    def load_json(path)
        path = @dir + path
        # Return no data if path doesn't exist
        return {} unless File.file?(path)
        # Otherwise load in file to JSON data
        file = File.open(path, encoding: "UTF-8")
        json = JSON.load(file)
        # Close file before returning JSON data
        file.close
        # Increment dictionary read count
        @read_count += 1
        return json
    end
end

$dictionary = Dictionary.new