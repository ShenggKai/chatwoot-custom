class Api::V1::JwtTokensController < ApplicationController
  require 'jwt'

  # POST /api/v1/jwt_token
  def create
    ipphone = params[:ipphone]
    expired = params[:expired]
    secret_key = params[:secret_key].presence || ENV['SECRET_KEY_3C']

    if ipphone.blank?
      render json: { error: 'Missing ipphone' }, status: :bad_request
      return
    end

    if secret_key.blank?
      render json: { error: 'Missing secret_key (not set in params or ENV)' }, status: :bad_request
      return
    end

    payload = { ipphone: ipphone }
    payload[:exp] = expired.to_i if expired.present?

    token = JWT.encode(payload, secret_key, 'HS256', { typ: 'JWT' })
    render json: { token: token }, status: :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end