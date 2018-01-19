# coding: utf-8

module Pomoengine
  MQTT_CONFIG = {
    host: 'localhost'
  }.freeze
#   CLIENT = MQTT::Client.connect(MQTT_CONFIG)
  START = Time.now
  FINISH = START + 25 * 60

  def pub(msg)
    CLIENT.publish('task/finish', msg)
    msg
  end

  class CLI < Thor
    desc 'timer', 'countdown timer and publish current'
    option :title, required: true
    def timer
      EM.run do
        stop_flag = false
        Signal.trap('INT')  { stop_flag = true }
        Signal.trap('TERM') { stop_flag = true }
        EM.add_periodic_timer(1) do
          duration = Time.now - START
          min = duration / 60
          sec = duration % 60
          puts "Tick ... #{min.to_i}分 #{sec.to_i}秒 経過"
          if stop_flag
            EM.stop_event_loop
            `say '#{options[:title]} 停止'`
            dynamo_db = Aws::DynamoDB::Resource.new
            table = dynamo_db.table('pomo_task')
            table.put_item(
              item:
                {
                  partition_key: Time.now.to_s,
                  start:         START.to_s,
                  title:         options[:title]
                }
            )
            return
          end
          if Time.now > FINISH
            # puts "#{Time.now} > #{FINISH} (#{Time.now > FINISH})"
            puts "#{Time.now} > #{FINISH} (#{Time.now > FINISH})"
            EM.stop_event_loop
            `say '#{options[:title]} 終了'`
            dynamo_db = Aws::DynamoDB::Resource.new
            table = dynamo_db.table('pomo_task')
            table.put_item(
              item:
                {
                  partition_key: Time.now.to_s,
                  start:         START.to_s,
                  title:         options[:title]
                }
            )
          end
        end
      end
    end
  end
end
