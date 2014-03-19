class RandomController < ApplicationController
    def index
        @random_view = true

        @quote = Quote.random
    end

    def show      
        @random_view = true

        @stream = Stream.where('LOWER(name) = ?', params[:id].downcase).first
        @quote = @stream.quotes.random
    end
end
