class QuotesController < ApplicationController
    before_filter :is_admin, only: [:edit, :update, :marked, :new, :create, :admin_quotes, :admin_toggle]

    def index
        @quote_dom_id = 0
        @page_one = (!params.has_key? :page) || (params[:page].eql? '1')
        @popular = (params.has_key? :popular)
        @starred = (params.has_key? :starred)
        @oldest = (params.has_key? :oldest)
        @latest = (!@popular and !@starred and !@oldest)
        @highlight_quote = (@starred || @popular) ? nil : Quote.where(highlight: true).random

        if @latest
            @quotes = Quote.paginate(page: params[:page], per_page: 10).order("created_at DESC")
        elsif @oldest
            @quotes = Quote.paginate(page: params[:page], per_page: 10).order("created_at ASC")
        elsif @popular
            @quotes = Quote.where({ text_art: false }).paginate(page: params[:page], per_page: 10).order("ip_likes_count DESC")
        elsif @starred
            @quotes = Quote.where({ highlight: true }).paginate(page: params[:page], per_page: 10).order("created_at DESC")
        end
    end

    def new
        @quote = Quote.new
    end

    def show
        if params.has_key?(:uncensored)
            unless Quote.exists?(params[:id])
                render 'general/server_error'
            else
                @quote = Quote.find(params[:id])
                @quote_dom_id = 0
                respond_to do |format|
                    format.js { render 'show_uncensored.js.erb' }
                end
            end      
        else
            @quote_dom_id = 0
            @quote = Quote.find(params[:id])

            respond_to do |format|
                format.html
                format.json { render json: @quote }
            end
        end
    end

    def edit
        @quote = Quote.find(params[:id])
    end

    def update
        @quote = Quote.find(params[:id])
        if @quote.update_attributes(quote_params)
            redirect_to @quote
        else
            render 'edit'
        end
    end

    def create
        @quote = Quote.new(quote_params)
        @stream = Stream.new(stream_params)

        if Stream.exists?(stream_id: params[:quote][:stream_id])
            save_quote(@quote)
        else
            if @stream.save
                save_quote(@quote)
            else
                flash.now[:error] = "Failed to save stream"
                render 'new'
            end
        end
    end

    def search
        @quote_dom_id = 0
        @search_type = (params.has_key? :search_type) ? params[:search_type] : "quote"
        @query = ""
        if (params.has_key? :query) and (!params[:query].empty?)
            @query = params[:query]
            if @search_type == "quote"
                @quotes = Quote.where("lower(quote) like ?", "%#{@query.downcase}%").paginate(page: params[:page], :per_page => 20).order("created_at DESC")
            else
                @quotes = Quote.where("lower(title) like ?", "%#{@query.downcase}%").paginate(page: params[:page], :per_page => 20).order("created_at DESC")
            end
        else
            @quotes = Quote.none.paginate(page: params[:page], :per_page => 20).order("created_at DESC")
        end
        render 'search_results'
    end

    def destroy
        @quote = Quote.find(params[:id])
        @quote.stream.quotes_count = @quote.stream.quotes.count
        @quote.delete
        redirect_to quotes_path
    end

    def show_marked_quote
        unless Quote.exists?(params[:id]) and params.has_key? :dom_id
            render 'general/server_error'
        else
            @quote = Quote.find(params[:id])
            @quote_dom_id = params[:dom_id]
            respond_to do |format|
                format.js
            end
        end
    end

    def marked
        @quotes = Quote.where.not( marked_as: nil ).paginate(page: params[:page], :per_page => 20).order("created_at DESC")
    end

    def admin_quotes
        if (params.has_key? :quote_id) and (!params[:quote_id].empty?)
            @quotes = Quote.where(id: params[:quote_id]).paginate(page: params[:page], :per_page => 20).order("created_at DESC")
        elsif (params.has_key? :quote_text) and (!params[:quote_text].empty?)
            @quotes = Quote.where("lower(quote) like ?", "%#{params[:quote_text].downcase}%").paginate(page: params[:page], :per_page => 20).order("created_at DESC")
        else
            @quotes = Quote.paginate(page: params[:page], per_page: 20).order("created_at DESC")
        end
    end

    def admin_toggle
        quote = Quote.find(params[:id])
        if params.has_key? :marked_as
            if !quote.is_marked_as? :profanity_auto
                quote.set_marked_as :profanity_auto
            else
                quote.remove_marked_as :profanity_auto
            end
        end
        if params.has_key? :highlight
            quote.highlight = !quote.highlight
        end
        quote.save
        redirect_to :back
    end

    def ascii_art
        @quote_dom_id = 0
        @quotes = Quote.where( text_art: true ).paginate(page: params[:page], :per_page => 17).order("created_at DESC")

        @quote_containers = @quotes.map { |quote| ASCIIArtQuoteContainer.new( model: quote ) }

        if @quote_containers.length < 6
            @quote_containers.push(ASCIIArtQuoteContainer.new( ad: true, id: 1 ))
            return
        end

        @quote_containers.insert(5, ASCIIArtQuoteContainer.new( ad: true, id: 1 ))

        if @quote_containers.length < 11
            return
        end

        @quote_containers.insert(11, ASCIIArtQuoteContainer.new( ad: true, id: 2 ))

        if @quote_containers.length < 17
            return
        end

        @quote_containers.insert(17, ASCIIArtQuoteContainer.new( ad: true, id: 3 ))
    end

    private
        def quote_params
            params.require(:quote).permit(:quote, :stream_id, :title, :text_art, :context)
        end

        def stream_params
            params.permit(:stream_id, :stream_name, :stream_url)
            return_params = ActionController::Parameters.new(stream_id: params[:quote][:stream_id], 
                name: params[:stream_name], 
                url: params[:stream_url],
                logo: params[:stream_logo],
                followers: params[:stream_followers] )
            return_params.permit!
        end

        def save_quote(quote)
            if quote.save
                quote.stream.quotes_count = quote.stream.quotes.count
                quote.stream.save
                redirect_to quotes_path
            else
                render 'new'
            end
        end
end