require "yaml"
require "discordrb"

# To handler Ctrl+C
Signal.trap("INT") do
  @bot.stop # Close websocket
  puts "
[Ctrl+C] Shutting Bot Because of Interrupt"
  exit
end

config = YAML.safe_load(File.open("config.yaml"))

@bot = Discordrb::Commands::CommandBot.new token: config["token"], prefix: "Rui "

@bot.ready do
  puts "#{@bot.bot_user.name} is connected to:"
  @bot.servers.each do |_k, v|
    puts "	#{v.name}"
  end
end

# Respond with hi to user
@bot.message(with_text: "Hey") do |event|
  event.respond "Hi, #{event.user.mention}!"
end

# Run the bot in another threads in the background by passing `true`
# Will block further execution if true not passed
@bot.run true

# Sends Invite URL, without any specific permissions
@bot.command :invite, description: "Send Invite URL, without any specific permissions" do |event|
  event.bot.invite_url
end

@bot.command(:ping, description: "Reply with Pong!") do |event|
  ping = event.respond "Pong!"
  ping.edit "Pong! Time taken: #{Time.now - event.timestamp} seconds."
  sleep 2
  ping.delete
  event.message.delete
end

# Connect to voice channel the user is conencted to
@bot.command :connect, description: "Connect to voice channel the user is connected to" do |event|
  channel = event.user.voice_channel # Current voice channel

  next "You're not in any voice channel!" unless channel

  @bot.voice_connect(channel) # Connect to voice channel
  "Connected to voice channel: #{channel.name}"
end

# Create a channel if user has admin role
@bot.command :"create-channel", min_args: 1, max_args: 1, description: "Create a channel if user has admin role" do |event, channel_name|
  if event.author.role?(config["admin_role"])
    if event.server.channels.any? { |channel| channel.name == channel_name }
      "Channel **#{channel_name}** already present in the server"
    else
      event.server.create_channel(channel_name)
      "Channel created with name **#{channel_name}**"
    end
  else
    "You don't have Admin role!!!"
  end
end

# Delete a channel if user has admin role
@bot.command :"delete-channel", min_args: 1, max_args: 1, description: "Delete channel if user has Admin role" do |event, channel_name|
  if event.author.role?(config["admin_role"])
    if event.server.channels.any? { |channel| channel.name == channel_name }
      c = event.server.channels.select { |channel| channel.name == channel_name }
      c[0].delete
      "Deleted Channel: **#{channel_name}**"
    else
      "**#{channel_name}** is not in the Server"
    end
  else
    "You don't have Admin role!!!"
  end
end

# Respond with server details
@bot.command :details, description: "Server's Details" do |event|
  server = event.server
  owner = server.owner
  server_id = server.id
  memberCount = server.member_count
  icon = server.icon_url
  bots = server.bot_members

  event.channel.send_embed("") do |embed|
    embed.title = "#{server.name} Server Information"
    embed.color = Discordrb::ColourRGB.new(rand(255)).to_i
    embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: icon)
    embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: owner.name, icon_url: owner.avatar_url)
    embed.add_field(name: "Server ID", value: server_id, inline: true)
    embed.add_field(name: "Member Count", value: memberCount, inline: true)
    embed.add_field(name: "Bot count", value: bots.length, inline: true)
  end
end

# Join the bot's thread back with the main thread:
@bot.join
