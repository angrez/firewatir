# Classes for all HTML Elements that FireWatir can address. This code is refactored from watir.rb file which was written
# specifically for IE.

class Frame 
        include Container

        # Find the frame denoted by how and what in the container and return its ole_object
        def locate
            how = @how
            what = @what
            frames = @container.document.frames
            target = nil

            for i in 0 .. (frames.length - 1)
                next unless target == nil
                this_frame = frames.item(i)
                if how == :index 
                    if i + 1 == what
                        target = this_frame
                    end
                elsif how == :name
                    begin
                        if what.matches(this_frame.name)
                            target = this_frame
                        end
                    rescue # access denied?
                    end
                elsif how == :id
                    # BUG: Won't work for IFRAMES
                    if what.matches(@container.document.getElementsByTagName("FRAME").item(i).invoke("id"))
                        target = this_frame
                    end
                else
                    raise ArgumentError, "Argument #{how} not supported"
                end
            end
            
            unless target
                raise UnknownFrameException, "Unable to locate a frame with name #{ what} " 
            end
            target        
        end
    
        def initialize(container, how, what)
            @container = container
            @how = how
            @what = what
            @o = locate
            copy_test_config container
        end

        def document
            @o.document
        end

	  alias getDocument document
        alias waitForIE wait

    end
    
    


    # Forms

    class Form < Element

        #   * container   - the containing object, normally an instance of IE
        #   * how         - symbol - how we access the form (:name, :id, :index, :action, :method)
        #   * what        - what we use to access the form
        def initialize(container, how, what)
            @container = Element.new(nil) #container
            @how = how
            @what = what
            
            log "Get form how is #{@how}  what is #{@what} "
            
            # Get form using xpath.
            if @how == :xpath    
                @o = @container.element_by_xpath(@what)
            else
                @o = @container.locate_tagged_element("form",@how, @what)
            end
        end

        # Submit the data -- equivalent to pressing Enter or Return to submit a form. 
        def submit # XXX use assert_exists
            @o.submit 
            @o.wait
        end   

        #def document
        #    return @ole_object
        #end

        #def wait(no_sleep = false)
        #    @container.wait(no_sleep)
        #end
                
        # This method is responsible for setting and clearing the colored highlighting on the specified form.
        # use :set   to set the highlight
        #   :clear  to clear the highlight
                
    end # class Form
    
    # this class contains items that are common between the span, div, and pre objects
    # it would not normally be used directly
    #
    # many of the methods available to this object are inherited from the Element class
    #
    class NonControlElement < Element
        include FireWatir::Exception
        #include Container
        
        def locate
            if @how == :xpath
                @o = @container.element_by_xpath(@what)
            else
                @o = @container.locate_tagged_element(self.class::TAG, @how, @what)
            end            
        end            
        
        def initialize(container, how, what)
            @container = Element.new(nil)
            @how = how
            @what = what
            super(nil)
        end
        
        # this method is used to populate the properties in the to_s method
        def span_div_string_creator
            n = []
            n <<   "class:".ljust(TO_S_SIZE) + self.class_name
            n <<   "text:".ljust(TO_S_SIZE) + self.text
            return n
        end
        private :span_div_string_creator
        
        # returns the properties of the object in a string
        # raises an ObjectNotFound exception if the object cannot be found
        #def to_s
        #    assert_exists
        #    r = string_creator
        #    r += span_div_string_creator
        #    return r.join("\n")
        #end
        
        #def ole_inner_elements
        #    puts "here"
        #end
    end
	
	class Pre < NonControlElement
		TAG = 'PRE'
		def self.tag; TAG; end
	end

    class P < NonControlElement 
        TAG = 'P'
        def self.tag; TAG; end
    end

    # this class is used to deal with Div tags in the html page. http://www.xulplanet.com/references/objref/HTMLDivElement.html 
    # It would not normally be created by users
    class Div < NonControlElement 
        TAG = 'DIV'
        def self.tag; TAG; end
    end

    # this class is used to deal with Span tags in the html page. It would not normally be created by users
    class Span < NonControlElement 
        TAG = 'SPAN'
        def self.tag; TAG; end
    end

    # Accesses Label element on the html page - http://www.xulplanet.com/references/objref/HTMLLabelElement.html
    class Label < NonControlElement
        TAG = 'LABEL'

        # this method is used to populate the properties in the to_s method
        def label_string_creator
            n = []
            n <<   "for:".ljust(TO_S_SIZE) + self.for
            n <<   "inner text:".ljust(TO_S_SIZE) + self.text
            return n
        end
        private :label_string_creator

        # returns the properties of the object in a string
        # raises an ObjectNotFound exception if the object cannot be found
        #def to_s
        #    assert_exists
        #    r = string_creator
        #    r=r + label_string_creator
        #    return r.join("\n")
        #end
    end

    # This class is used for dealing with tables.
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#table method
    #
    # many of the methods available to this object are inherited from the Element class
    #
    class Table < Element
        
        # Returns the table object containing anElement
        #   * container  - an instance of an IE object
        #   * anElement  - a FireWatir object (TextField, Button, etc.)
        def Table.create_from_element(container, anElement)
            anElement.locate if defined?(anElement.locate)
            o = anElement.ole_object.parentElement
            o = o.parentElement until o.tagName == 'TABLE'
            Table.new(container, :direct, o)
        end

        # Returns an initialized instance of a table object
        #   * container      - the container
        #   * how         - symbol - how we access the table
        #   * what         - what we use to access the table - id, name index etc 
        def initialize(container, how, what)
            @container = Element.new(nil)
            @how = how
            @what = what
            super nil
        end

        def locate
            if @how == :xpath
                @o = @container.element_by_xpath(@what)
            elsif @how == :direct
                @o = @what
            else
                @o = @container.locate_tagged_element('TABLE', @how, @what)
            end
        end
        
        # override the highlight method, as if the tables rows are set to have a background color, 
        # this will override the table background color,  and the normal flsh method wont work
        def highlight(set_or_clear )

           if set_or_clear == :set
                begin
                    @original_border = @o.border.to_i
                    if @o.border.to_i==1
                        @o.border = 2
                    else
                        @o.border=1
                    end
                rescue
                    @original_border = nil
                end
            else
                begin 
                    @o.border= @original_border unless @original_border == nil
                    @original_border = nil
                rescue
                    # we could be here for a number of reasons...
                ensure
                    @original_border = nil
                end
            end
            super    
        end

        # this method is used to ppulate the properties in the to_s method
        def table_string_creator
            n = []
            n <<   "rows:".ljust(TO_S_SIZE) + self.row_count.to_s
            n <<   "cols:".ljust(TO_S_SIZE) + self.column_count.to_s
            return n
        end
        private :table_string_creator

        # returns the properties of the object in a string
        # raises an ObjectNotFound exception if the object cannot be found
        #def to_s
        #    assert_exists
        #    r = string_creator
        #    r=r + table_string_creator
        #    return r.join("\n")
        #end

        # iterates through the rows in the table. Yields a TableRow object
        #def each
        #    assert_exists
        #    1.upto( @o.getElementsByTagName("TR").length) { |i|  yield TableRow.new(@container, :direct, row(i) )    }
        #end
 
        # Returns a row in the table
        #   * index         - the index of the row
        #def [](index)
        #    assert_exists

        #end

        # This method returns the number of rows in the table.
        # Raises an UnknownObjectException if the table doesnt exist.
        def row_count 
            assert_exists
            #return table_body.children.length
            return @o.get_rows.length
        end

        # This method returns the number of columns in a row of the table.
        # Raises an UnknownObjectException if the table doesn't exist.
        #   * index         - the index of the row
        #def column_count(index=1) 
        #    assert_exists
        #    row(index).cells.length
        #end

        # This method returns the table as a 2 dimensional array. Dont expect too much if there are nested tables, colspan etc.
        # Raises an UnknownObjectException if the table doesn't exist.
        def to_a
            assert_exists
            y = []
            table_rows = @o.get_rows()
            for row in table_rows
                x = []
                row.each do |td|
                    x << td.to_s.strip
                end
                y << x
            end
            return y
        end

        #def table_body(index = 1)
        #    return @o.getElementsByTagName('TBODY')[index]
        #end
        #private :table_body

        # returns a FireWatir object
        #def body(how, what)
        #    return TableBody.new(@container, how, what, self)
        #end

        # returns a FireWatir object
        #def bodies
        #    assert_exists
        #    return TableBodies.new(@container, @o)
        #end
   
        # returns an ole object
        #def row(index) 
        #    return @o.invoke("rows")[(index-1).to_s]
        #end
        #private :row

        # Returns an array containing all the text values in the specified column
        # Raises an UnknownCellException if the specified column does not exist in every
        # Raises an UnknownObjectException if the table doesn't exist.
        # row of the table
        #   * columnnumber  - column index to extract values from
        #def column_values(columnnumber)
        #    return (1..row_count).collect {|idx| self[idx][columnnumber].text}
        #end
        
        # Returns an array containing all the text values in the specified row
        # Raises an UnknownObjectException if the table doesn't exist.
        #   * rownumber  - row index to extract values from
        #def row_values(rownumber)
        #    return (1..column_count(rownumber)).collect {|idx| self[rownumber][idx].text}
        #end

        def rows
            assert_exists
            @o.get_rows()
        end
    end

    # this class is a collection of the table body objects that exist in the table
    # it wouldnt normally be created by a user, but gets returned by the bodies method of the Table object
    # many of the methods available to this object are inherited from the Element class
    #
    class TableBodies < Element 
        def initialize(container, parent_table)
            @container = container
            @o = parent_table     # in this case, @o is the parent table
        end
 
        # returns the number of TableBodies that exist in the table
        def length
            assert_exists
            return @o.tBodies.length
        end

        # returns the n'th Body as a FireWatir TableBody object
        def []n
            assert_exists
            return TableBody.new(@container, :direct, ole_table_body_at_index(n))
        end

        # returns an ole table body
        def ole_table_body_at_index(n)
            return @o.tBodies[(n-1).to_s]
        end

        # iterates through each of the TableBodies in the Table. Yields a TableBody object
        def each
            1.upto( @o.tBodies.length ) { |i| yield TableBody.new(@container, :direct, ole_table_body_at_index(i)) }
        end

    end

    # this class is a table body
    class TableBody < Element
        def locate
            @o = nil
            if @how == :direct
                @o = @what     # in this case, @o is the table body
            elsif @how == :index
                @o = @parent_table.bodies.ole_table_body_at_index(@what)
            end
            @rows = []
            if @o
                @o.rows.each do |oo|
                    @rows << TableRow.new(@container, :direct, oo)
                end
            end
        end            

        def initialize(container, how, what, parent_table = nil)
            @container = container
            @how = how
            @what = what
            @parent_table = parent_table
            super nil
        end
 
        # returns the specified row as a TableRow object
        def [](n)
            assert_exists
            return @rows[n - 1]
        end

        # iterates through all the rows in the table body
        def each
            locate
            0.upto(@rows.length - 1) { |i| yield @rows[i] }
        end

        # returns the number of rows in this table body.
        def length
           return @rows.length
        end
    end


    # this class is a table row
    class TableRow < Element

        def locate
            @o = nil
            #if @how == :direct
            #    @o = @what
            if @how == :xpath
                @o = @container.element_by_xpath(@what)
            else
                @o = @container.locate_tagged_element("TR", @how, @what)   
            end
        end

        # Returns an initialized instance of a table row          
        #   * o  - the object contained in the row
        #   * container  - an instance of an IE object       
        #   * how          - symbol - how we access the row        
        #   * what         - what we use to access the row - id, index etc. If how is :direct then what is a Internet Explorer Raw Row 
        def initialize(container, how, what)
            @container = Element.new(nil) #container
            @how = how   
            @what = what   
            super nil
        end
   
        # this method iterates through each of the cells in the row. Yields a TableCell object
        #def each
        #    assert_exists
        #    0.upto( @cells.length-1 ) { |i| yield @cells[i] }
        #end

   	    # Returns an element from the row as a TableCell object
        #def [](index)
        #    assert_exists
        #    raise UnknownCellException, "Unable to locate a cell at index #{index}" if @cells.length < index
        #    return @cells[(index - 1)]
        #end

        # defaults all missing methods to the array of elements, to be able to
        # use the row as an array
#        def method_missing(aSymbol, *args)
#            return @o.send(aSymbol, *args)
#        end
   
        def column_count
            assert_exists
            @o.cells.length
        end
    end
 
    # this class is a table cell - when called via the Table object
    class TableCell < Element

        def locate
            if @how == :xpath
                @o = @container.element_by_xpath(@what)
            else
                @o = @container.locate_tagged_element("TD", @how, @what)   
            end
        end

        # Returns an initialized instance of a table cell          
        #   * container  - an  IE object       
        #   * how        - symbol - how we access the cell        
        #   * what       - what we use to access the cell - id, name index etc
        def initialize(container, how, what)   
            @container = Element.new(nil) #container    
            @how = how   
            @what = what   
            super nil   
        end 

        alias to_s text
 
        def colspan
            assert_exists
            @o.colSpan
        end

   end

    # This class is the means of accessing an image on a page.
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#image method
    #
    # many of the methods available to this object are inherited from the Element class
    #
    class Image < Element
        def initialize(container, how, what)
            @container = Element.new(nil)
            @how = how
            @what = what
        end
        
        def locate
            if @how == :xpath
                @o = @container.element_by_xpath(@what)
            else
                @o = @container.locate_tagged_element('IMG', @how, @what)
            end            
        end            

        # this method produces the properties for an image as an array
        def image_string_creator
            n = []
            n <<   "src:".ljust(TO_S_SIZE) + self.src.to_s
            n <<   "file date:".ljust(TO_S_SIZE) + self.fileCreatedDate.to_s
            n <<   "file size:".ljust(TO_S_SIZE) + self.fileSize.to_s
            n <<   "width:".ljust(TO_S_SIZE) + self.width.to_s
            n <<   "height:".ljust(TO_S_SIZE) + self.height.to_s
            n <<   "alt:".ljust(TO_S_SIZE) + self.alt.to_s
            return n
        end
        private :image_string_creator

        # returns a string representation of the object
        #def to_s
        #    assert_exists
        #    r = string_creator
        #    r=r + image_string_creator
        #    return r.join("\n")
        #end

        # this method returns the file created date of the image
        def fileCreatedDate
            assert_exists
            return @o.invoke("fileCreatedDate")
        end

        # this method returns the filesize of the image
        def fileSize
            assert_exists
            return @o.invoke("fileSize").to_s
        end

        # returns the width in pixels of the image, as a string
        def width
            assert_exists
            return @o.invoke("width").to_s
        end

        # returns the height in pixels of the image, as a string
        def height
            assert_exists
            return @o.invoke("height").to_s
        end

        # This method attempts to find out if the image was actually loaded by the web browser. 
        # If the image was not loaded, the browser is unable to determine some of the properties. 
        # We look for these missing properties to see if the image is really there or not. 
        # If the Disk cache is full ( tools menu -> Internet options -> Temporary Internet Files) , it may produce incorrect responses.
        #def hasLoaded?
        #    locate
        #    raise UnknownObjectException, "Unable to locate image using #{@how} and #{@what}" if @o == nil
        #    return false if @o.fileCreatedDate == "" and  @o.fileSize.to_i == -1
        #    return true
        #end

        # this method highlights the image ( in fact it adds or removes a border around the image)
        #  * set_or_clear   - symbol - :set to set the border, :clear to remove it
        def highlight( set_or_clear )
            if set_or_clear == :set
                begin
                    @original_border = @o.border
                    @o.border = 1
                rescue
                    @original_border = nil
                end
            else
                begin 
                    @o.border = @original_border 
                    @original_border = nil
                rescue
                    # we could be here for a number of reasons...
                ensure
                    @original_border = nil
                end
            end
        end
        private :highlight
    end                                                      
    
    
    # This class is the means of accessing a link on a page
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#link method
    # many of the methods available to this object are inherited from the Element class
    #
    class Link < Element
        # Returns an initialized instance of a link object
        #   * container  - an instance of a container
        #   * how         - symbol - how we access the link
        #   * what         - what we use to access the link, text, url, index etc
        def initialize(container, how, what)
            @container = Element.new(nil)
            @how = how
            @what = what
        end
        
        def locate
            if @how == :xpath
                @o = @container.element_by_xpath(@what)
            else
            begin
                @o = @container.locate_tagged_element('A', @how, @what)
            rescue UnknownObjectException
                @o = nil
            end
        end
        end

        #TODO: if an image is used as part of the link, this will return true      
        #def link_has_image
        #    assert_exists
        #    return true  if @o.getElementsByTagName("IMG").length > 0
        #    return false
        #end

        #TODO: this method returns the src of an image, if an image is used as part of the link
        #def src # BUG?
        #    assert_exists
        #    if @o.getElementsByTagName("IMG").length > 0
        #        return  @o.getElementsByTagName("IMG")[0.to_s].src
        #    else
        #        return ""
        #    end
        #end

        def link_string_creator
            n = []
            n <<   "href:".ljust(TO_S_SIZE) + self.href
            n <<   "inner text:".ljust(TO_S_SIZE) + self.text
            n <<   "img src:".ljust(TO_S_SIZE) + self.src if self.link_has_image
            return n
         end

         # returns a textual description of the link
         #def to_s
         #   assert_exists
         #   r = string_creator
         #   r = r + link_string_creator
         #   return r.join("\n")
         #end
    end
    
    class InputElement < Element
        def locate
            if @how == :xpath
                @o = @container.element_by_xpath(@what)
            #elsif @how == :direct
            #    @o = @what
            else
                if(self.class::INPUT_TYPES.include?("select-one"))
                    @o = @container.locate_tagged_element("select", @how, @what, self.class::INPUT_TYPES)
                else    
                    @o = @container.locate_tagged_element("input", @how, @what, self.class::INPUT_TYPES)
                end    
            end              
        end
        def initialize(container, how, what)
            @container = Element.new(nil)
            @how = how
            @what = what
            super(nil)
        end
    end
    
    # This class is the way in which select boxes are manipulated.
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#select_list method
    class SelectList < InputElement
        INPUT_TYPES = ["select-one", "select-multiple"]
        
        attr_accessor :o
        
        #def each

        #end
        # This method clears the selected items in the select box
        def clearSelection
            assert_exists
            #highlight( :set)
            wait = false
            for i in 0..@o.length - 1 do
            #@o.each do |selectBoxItem|
                selectBoxItem = @o.options[i]
                if selectBoxItem.selected
                    selectBoxItem.selected = false
                    wait = true
                end
            end
            @container.wait if wait
            #highlight( :clear)
        end
#        private :clearSelection
        
        # This method selects an item, or items in a select box, by text.
        # Raises NoValueFoundException   if the specified value is not found.
        #  * item   - the thing to select, string or reg exp
        def select( item )
            select_item_in_select_list(:text, item)
        end

        # Selects an item, or items in a select box, by value.
        # Raises NoValueFoundException   if the specified value is not found.
        #  * item   - the value of the thing to select, string, reg exp or an array of string and reg exps
        def select_value( item )
            select_item_in_select_list( :value , item )
        end

        # BUG: Should be private
        # Selects something from the select box
        #  * name  - symbol  :value or :text - how we find an item in the select box
        #  * item  - string or reg exp - what we are looking for
        def select_item_in_select_list(attribute, value)
            assert_exists
            highlight( :set )
            doBreak = false
            #@container.log "Setting box #{@o.name} to #{attribute} #{value} "
            @o.each do |option| # items in the list
                if value.matches( option.invoke(attribute.to_s))
                    if option.selected
                        doBreak = true
                        break
                    else
                        option.selected = true
                        @o.fireEvent("onChange")
                        @container.wait
                        doBreak = true
                        break
                    end
                end
            end
            unless doBreak
                raise NoValueFoundException, 
                        "No option with #{attribute.to_s} of #{value} in this select element"  
            end
            highlight( :clear )
        end
        
        # Returns all the items in the select list as an array. 
        # An empty array is returned if the select box has no contents.
        # Raises UnknownObjectException if the select box is not found
        def getAllContents() # BUG: camel_case.rb
            assert_exists
            #@container.log "There are #{@o.length} items"
            returnArray = []
            @o.each { |thisItem| returnArray << thisItem.text }
            return returnArray 
        end
        
        # Returns the selected items as an array.
        # Raises UnknownObjectException if the select box is not found.
        def getSelectedItems
            assert_exists
            returnArray = []
            #@container.log "There are #{@o.length} items"
            @o.each do |thisItem|
                if thisItem.selected
                    #@container.log "Item ( #{thisItem.text} ) is selected"
                    returnArray << thisItem.text 
                end
            end
            return returnArray 
        end
        
        def option (attribute, value)
            assert_exists
            Option.new(self, attribute, value)
        end
    end

    module OptionAccess
        def text
            @option.text
        end
        def value
            @option.value
        end
        def selected
            @option.selected
        end
    end

    class OptionWrapper
        include OptionAccess
        def initialize (option)
            @option = option
        end
    end

    # An item in a select list
    class Option 
        include OptionAccess
        include FireWatir::Exception
        def initialize (select_list, attribute, value)
            @select_list = select_list
            @how = attribute
            @what = value
            @option = nil
            
            unless [:text, :value].include? attribute 
                raise MissingWayOfFindingObjectException,
                    "Option does not support attribute #{@how}"
            end
            #puts @select_list.o.length
            @select_list.o.each do |option| # items in the list
                if value.matches( option.invoke(attribute.to_s))
                    @option = option
                    break
                end
            end
        end
        def assert_exists
            unless @option
                raise UnknownObjectException,  
                    "Unable to locate an option using #{@how} and #{@what}"
            end
        end
        private :assert_exists
        def select
            assert_exists
            @select_list.select_item_in_select_list(@how, @what)
        end
        def class_name
            assert_exists
            @option.class_name
        end
    end    

    # This is the main class for accessing buttons.
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#button method
    class Button < InputElement
        INPUT_TYPES = ["button", "submit", "image", "reset"] 
    end
    
    # This class is the main class for Text Fields
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#text_field method
    class TextField < InputElement
        INPUT_TYPES = ["text", "password", "textarea"] 

        def_wrap_guard :size
        def_wrap_guard :maxlength

        # Returns true or false if the text field is read only.
        #   Raises  UnknownObjectException if the object can't be found.
        def_wrap :readonly?, :readOnly

        def text_string_creator
            n = []
            n <<   "length:".ljust(TO_S_SIZE) + self.size.to_s
            n <<   "max length:".ljust(TO_S_SIZE) + self.maxlength.to_s
            n <<   "read only:".ljust(TO_S_SIZE) + self.readonly?.to_s

            return n
         end
         private :text_string_creator

         #def to_s
         #   assert_exists
         #   r = string_creator
         #   r += text_string_creator
         #   return r.join("\n")
         #end
        
        def assert_not_readonly
            raise ObjectReadOnlyException, "Textfield #{@how} and #{@what} is read only." if self.readonly?
        end                

        # This method returns true or false if the text field contents is either a string match 
        # or a regular expression match to the supplied value.
        #   Raises  UnknownObjectException if the object can't be found
        #   * containsThis - string or reg exp  -  the text to verify 
        def verify_contains( containsThis ) # BUG: Should have same name and semantics as IE#contains_text (prolly make this work for all elements)
            assert_exists            
            if containsThis.kind_of? String
                return true if self.value == containsThis
            elsif containsThis.kind_of? Regexp
                return true if self.value.match(containsThis) != nil
            end
            return false
        end

        # this method is used to drag the entire contents of the text field to another text field
        #  19 Jan 2005 - It is added as prototype functionality, and may change
        #   * destination_how   - symbol, :id, :name how we identify the drop target 
        #   * destination_what  - string or regular expression, the name, id, etc of the text field that will be the drop target
        def dragContentsTo( destination_how , destination_what)
            assert_exists
            destination = @container.text_field(destination_how, destination_what)
            raise UnknownObjectException ,  "Unable to locate destination using #{destination_how } and #{destination_what } "   if destination.exists? == false

            @o.focus
            @o.select()
            value = self.value

            @o.fireEvent("onSelect")
            @o.fireEvent("ondragstart")
            @o.fireEvent("ondrag")
            destination.fireEvent("onDragEnter")
            destination.fireEvent("onDragOver")
            destination.fireEvent("ondrop")

            @o.fireEvent("ondragend")
            destination.value= ( destination.value + value.to_s  )
            self.value = ""
        end

        # This method clears the contents of the text box.
        #   Raises  UnknownObjectException if the object can't be found
        #   Raises  ObjectDisabledException if the object is disabled
        #   Raises  ObjectReadOnlyException if the object is read only
        def clear
            assert_exists
            assert_enabled
            assert_not_readonly
            
            highlight(:set)
            
            @o.scrollIntoView
            @o.focus
            @o.select()
            @o.fireEvent("onSelect")
            @o.value = ""
            @o.fireEvent("onKeyPress")
            @o.fireEvent("onChange")
            @container.wait()
            highlight(:clear)
        end
        
        # This method appens the supplied text to the contents of the text box.
        #   Raises  UnknownObjectException if the object cant be found
        #   Raises  ObjectDisabledException if the object is disabled
        #   Raises  ObjectReadOnlyException if the object is read only
        #   * setThis  - string - the text to append
        def append( setThis)
            assert_exists
            assert_enabled
            assert_not_readonly
            
            highlight(:set)
            @o.scrollIntoView
            @o.focus
            doKeyPress( setThis )
            highlight(:clear)
        end
        
        # This method sets the contents of the text box to the supplied text 
        #   Raises  UnknownObjectException if the object cant be found
        #   Raises  ObjectDisabledException if the object is disabled
        #   Raises  ObjectReadOnlyException if the object is read only
        #   * setThis  - string - the text to set 
        def set( setThis )
            assert_exists
            assert_enabled
            assert_not_readonly
            
            highlight(:set)
            @o.scrollIntoView
            @o.focus
            @o.select()
            @o.fireEvent("onSelect")
            @o.value = ""
            @o.fireEvent("onKeyPress")
            doKeyPress( setThis )
            highlight(:clear)
            @o.fireEvent("onChange")
            @o.fireEvent("onBlur")
        end
        
        # this method sets the value of the text field directly. It causes no events to be fired or exceptions to be raised, so generally shouldnt be used
        # it is preffered to use the set method.
        def value=(v)
            assert_exists
            @o.value = v.to_s
        end

        # This method is used internally by setText and appendText
        # It should not be used externally.
        #   * value   - string  - The string to enter into the text field
        def doKeyPress( value )
            begin
                maxLength = @o.maxLength
                if (maxLength != -1 && value.length > maxLength)
                    original_value = value
                    value = original_value[0..maxLength]
                    @container.log " Supplied string is #{suppliedValue.length} chars, which exceeds the max length (#{maxLength}) of the field. Using value: #{value}"
                end
            rescue
                # probably a text area - so it doesnt have a max Length
                maxLength = -1
            end
            for i in 0..value.length-1   
                #sleep @container.typingspeed   # typing speed
                c = value[i,1]
                #@container.log  " adding c.chr " + c  #.chr.to_s
                @o.value = (@o.value.to_s + c)   #c.chr
                @o.fireEvent("onKeyDown")
                @o.fireEvent("onKeyPress")
                @o.fireEvent("onKeyUp")
            end
            
        end
        private :doKeyPress

	  alias readOnly? :readonly?
        alias getContents value
        alias maxLength maxlength
		
    end

    # this class can be used to access hidden field objects
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#hidden method
    class Hidden < TextField 
        INPUT_TYPES =  ["hidden"]
       
        # set is overriden in this class, as there is no way to set focus to a hidden field
        def set(n)
            self.value=n
        end
 
        # override the append method, so that focus isnt set to the hidden object
        def append(n)
            self.value = self.value.to_s + n.to_s
        end

        # override the clear method, so that focus isnt set to the hidden object
        def clear
            self.value = ""
        end

        # this method will do nothing, as you cant set focus to a hidden field
        def focus
        end

    end

    class FileField < InputElement
        INPUT_TYPES = ["file"]

        def set(setPath)
            assert_exists
            
            setFileFieldValue(setPath)
        end
    end

    # This class is the class for radio buttons and check boxes. 
    # It contains methods common to both.
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#checkbox or FireWatir::Container#radio methods
    #
    # most of the methods available to this element are inherited from the Element class
    #
    class RadioCheckCommon < Element
        def locate
            if @how == :xpath
                @o = @container.element_by_xpath(@what)
            else
                @o = @container.locate_tagged_element("input", @how, @what, @type, @value)
            end
        end
        def initialize(container, how, what, type, value = nil)
            @container = Element.new(nil)
            @how = how
            @what = what
            @type = type
            @value = value
        end

        # BUG: rename me
        # This method determines if a radio button or check box is set.
        # Returns true is set/checked or false if not set/checked.
        # Raises UnknownObjectException if its unable to locate an object.
        def isSet?
            assert_exists
            return @o.checked
        end
        alias getState isSet?
        #alias checked? isSet?
        
        # This method clears a radio button or check box. Note, with radio buttons one of them will almost always be set.
        # Returns true if set or false if not set.
        #   Raises UnknownObjectException if its unable to locate an object
        #         ObjectDisabledException  IF THE OBJECT IS DISABLED 
        def clear
            assert_exists
            assert_enabled
            #highlight(:set)
            set_clear_item(false)
            #highlight(:clear)
        end
        
        # This method sets the radio list item or check box.
        #   Raises UnknownObjectException  if its unable to locate an object
        #         ObjectDisabledException  if the object is disabled 
        def set
            assert_exists
            assert_enabled
            #highlight(:set)
            set_clear_item(true)
            #highlight(:clear)
        end
    
        # This method is the common code for setting or clearing checkboxes and radio.
        def set_clear_item(set)
            @o.checked = set
            @o.fireEvent("onClick")
            @container.wait
        end
        private :set_clear_item
    
    end

    #--
    #  this class makes the docs better
    #++
    # This class is the FireWatir representation of a radio button.        
    class Radio < RadioCheckCommon 
    end

    # This class is the FireWatir representation of a check box.
    class CheckBox < RadioCheckCommon 

        # This method, with no arguments supplied, sets the check box.
        # If the optional set_or_clear is supplied, the checkbox is set, when its true and cleared when its false
        #   Raises UnknownObjectException  if its unable to locate an object
        #         ObjectDisabledException  if the object is disabled 
        def set( set_or_clear=true )
            assert_exists
            assert_enabled
            highlight( :set)

            if set_or_clear == true
                if @o.checked == false
                    set_clear_item( true )
                end
            else
                self.clear
            end
            highlight( :clear )
        end
        
        # This method clears a check box. 
        # Returns true if set or false if not set.
        #   Raises UnknownObjectException if its unable to locate an object
        #         ObjectDisabledException  if the object is disabled 
        def clear
            assert_exists
            assert_enabled
            highlight( :set)
            if @o.checked == true
                set_clear_item( false )
            end
            highlight( :clear)
        end
    end
    
    # this class is the super class for the iterator classes ( buttons, links, spans etc
    # it would normally only be accessed by the iterator methods ( spans , links etc) of IE
    class ElementCollections
        include Enumerable
        include Container
        # Super class for all the iteractor classes
        #   * container  - an instance of an IE object
        def initialize( container)
            @container = container
            @length = length() # defined by subclasses

            # set up the items we want to display when the show method s used
            set_show_items
        end
 
        private 
        def set_show_items
            @show_attributes = AttributeLengthPairs.new( "id" , 20)
            @show_attributes.add( "name" , 20)
        end

        public
        def get_length_of_input_objects(object_type) 
            object_types = 
                if object_type.kind_of? Array 
                    object_type  
                else
                    [ object_type ]
                end

            length = 0
            objects = @container.document.getElementsByTagName("INPUT")
            if  objects.length > 0 
                objects.each do |o|
                   length += 1 if object_types.include?(o.invoke("type").downcase )
                end
            end    
            return length
        end

        # iterate through each of the elements in the collection in turn
        def each
            0.upto( @length-1 ) { |i | yield iterator_object(i) }
        end

        # allows access to a specific item in the collection
        def [](n)
            return iterator_object(n-1)
        end

        # this method is the way to show the objects, normally used from irb
        def show
            s="index".ljust(6)
            @show_attributes.each do |attribute_length_pair| 
                s=s + attribute_length_pair.attribute.ljust(attribute_length_pair.length)
            end

            index = 1
            self.each do |o|
                s= s+"\n"
                s=s + index.to_s.ljust(6)
                @show_attributes.each do |attribute_length_pair| 
                    begin
                        s=s  + eval( 'o.getOLEObject.invoke("#{attribute_length_pair.attribute}")').to_s.ljust( attribute_length_pair.length  )
                    rescue=>e
                        s=s+ " ".ljust( attribute_length_pair.length )
                    end
                end
                index+=1
            end
            puts s 
        end

        # this method creates an object of the correct type that the iterators use
        private
        def iterator_object(i)
            element_class.new(@container, :index, i+1)
        end
    end

    #--
    #   These classes are not for public consumption, so we switch off rdoc


    # presumes element_class or element_tag is defined
    # for subclasses of ElementCollections
    module CommonCollection
        def element_tag
            element_class.tag
        end
        def length
            @container.document.getElementsByTagName(element_tag).length
        end
    end        
    
    # This class is used as part of the .show method of the iterators class
    # it would not normally be used by a user
    class AttributeLengthPairs
        
        # This class is used as part of the .show method of the iterators class
        # it would not normally be used by a user
        class AttributeLengthHolder
            attr_accessor :attribute
            attr_accessor :length
            
            def initialize( attrib, length)
                @attribute = attrib
                @length = length
            end
        end
        
        def initialize( attrib=nil , length=nil)
            @attr=[]
            add( attrib , length ) if attrib
            @index_counter=0
        end

        # BUG: Untested. (Null implementation passes all tests.)
        def add( attrib , length)
            @attr <<  AttributeLengthHolder.new( attrib , length )
        end

        def delete(attrib)
            item_to_delete=nil
            @attr.each_with_index do |e,i|
                item_to_delete = i if e.attribute==attrib
            end
            @attr.delete_at(item_to_delete ) unless item_to_delete == nil
        end

        def next
            temp = @attr[@index_counter]
            @index_counter +=1
            return temp
        end

        def each
             0.upto( @attr.length-1 ) { |i | yield @attr[i]   }
        end
    end

    #    resume rdoc
    #++   
    

    # this class accesses the buttons in the document as a collection
    # it would normally only be accessed by the FireWatir::Container#buttons method
    #
    class Buttons < ElementCollections
        def element_class; Button; end
        def length
            get_length_of_input_objects(["button", "submit", "image"])
        end

        private
        def set_show_items
            super
            @show_attributes.add( "disabled" , 9)
            @show_attributes.add( "value" , 20)
        end
    end


    # this class accesses the file fields in the document as a collection
    # it would normally only be accessed by the FireWatir::Container#file_fields method
    #
    class FileFields< ElementCollections
        def element_class; FileField; end
        def length
            get_length_of_input_objects(["file"])
        end

        private
        def set_show_items
            super
            @show_attributes.add( "disabled" , 9)
            @show_attributes.add( "value" , 20)
        end
    end


    # this class accesses the check boxes in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#checkboxes method
    #
    class CheckBoxes < ElementCollections
        def element_class; CheckBox; end  
        def length
            get_length_of_input_objects("checkbox")
        end
        # this method creates an object of the correct type that the iterators use
        private
        def iterator_object(i)
            @container.checkbox(:index, i+1)
        end
    end

    # this class accesses the radio buttons in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#radios method
    #
    class Radios < ElementCollections
        def element_class; Radio; end
        def length
            get_length_of_input_objects("radio")
        end
        # this method creates an object of the correct type that the iterators use
        private
        def iterator_object(i)
            @container.radio(:index, i+1)
        end
    end

    # this class accesses the select boxes  in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#select_lists method
    #
    class SelectLists < ElementCollections
        include CommonCollection
        def element_class; SelectList; end
        def element_tag; 'SELECT'; end
    end

    # this class accesses the links in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#links method
    #
    class Links < ElementCollections
        include CommonCollection
        def element_class; Link; end    
        def element_tag; 'A'; end

        private 
        def set_show_items
            super
            @show_attributes.add("href", 60)
            @show_attributes.add("innerText" , 60)
        end

    end

    # this class accesses the imnages in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#images method
    #
    class Images < ElementCollections
        def element_class; Image; end 
        def length
            @container.document.images.length
        end

        private 
        def set_show_items
            super
            @show_attributes.add("src", 60)
            @show_attributes.add("alt", 30)
        end 

    end

    # this class accesses the text fields in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#text_fields method
    #
    class TextFields < ElementCollections
        def element_class; TextField; end
        def length
            # text areas are also included in the TextFields, but we need to get them seperately
            get_length_of_input_objects( ["text" , "password"] ) +
                @container.document.getElementsByTagName("textarea").length
        end
    end

    # this class accesses the hidden fields in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#hiddens method
    class Hiddens < ElementCollections
        def element_class; Hidden; end
        def length
            get_length_of_input_objects("hidden")
        end
    end

    # this class accesses the text fields in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#tables method
    #
    class Tables < ElementCollections
        include CommonCollection
        def element_class; Table; end
        def element_tag; 'TABLE'; end

        private 
        def set_show_items
            super
            @show_attributes.delete( "name")
        end
    end

    # this class accesses the labels in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#labels method
    #
    class Labels < ElementCollections
        include CommonCollection
        def element_class; Label; end
        def element_tag; 'LABEL'; end

        private 
        def set_show_items
            super
            @show_attributes.add("htmlFor", 20)
        end
    end
	
    # this class accesses the p tags in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#ps method
    #
	class Pres < ElementCollections
		include CommonCollection
		def element_class; Pre; end
		
		def set_show_items
			super
			@show_attributes.delete( "name" )
			@show_attributes.add( "className", 20 )
		end
	end

    # this class accesses the p tags in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#ps method
    #
    class Ps < ElementCollections
        include CommonCollection
        def element_class; P; end

        private
        def set_show_items
            super
            @show_attributes.delete( "name")
            @show_attributes.add( "className" , 20)
        end

    end

    # this class accesses the spans in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#spans method
    #
    class Spans < ElementCollections
        include CommonCollection
        def element_class; Span; end

        private
        def set_show_items
            super
            @show_attributes.delete( "name")
            @show_attributes.add( "className" , 20)
        end

    end

    # this class accesses the divs in the document as a collection
    # Normally a user would not need to create this object as it is returned by the FireWatir::Container#divs method
    #
    class Divs < ElementCollections
        include CommonCollection
        def element_class; Div; end

        private 
        def set_show_items
            super
            @show_attributes.delete( "name")
            @show_attributes.add( "className" , 20)
        end

    end
