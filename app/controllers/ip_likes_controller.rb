class IpLikesController < ApplicationController
    before_filter :setup

    def create
        @ip_like = IpLike.new(ip_like_params)

        if @ip_like.save
            respond_to do |format|
                format.js
            end
        else
            render 'general/server_error'
        end
    end

    def destroy
        ip_like = IpLike.find(params[:id])
        ip_like.destroy

        if !IpLike.exists?(params[:id])
            respond_to do |format|
                format.js
            end
        else
            render 'general/server_error'
        end
    end

    private
        def ip_like_params
            # THIS FAILS??? D:
            # if current_ip_user.nil?
            #     ip_user = IpUser.new(ip_address: request.remote_ip)
            #     if ip_user.save
            #         current_ip_user = ip_user
            #     end
            # end

            create_current_ip_user if current_ip_user.nil?

            return_params = ActionController::Parameters.new(
                quote_id: params[:quote_id],
                ip_user_id: current_ip_user.id
            )

            return_params.permit!
        end

        def setup
            @quote = Quote.find(params[:quote_id])
            @quote_dom_id = params[:quote_dom_id]
        end
end
