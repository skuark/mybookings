# This migration comes from mybookings (originally 20140330130210)
class AddsBasicAssociationsToUserBookingAndResource < ActiveRecord::Migration
  def change
    create_table :mybookings_bookings do |t|
      t.belongs_to :user
      t.belongs_to :resource
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end

    add_index :mybookings_bookings, [ :user_id, :resource_id ]

    create_table :mybookings_resources do |t|
      t.string :name

      t.timestamps
    end

    add_index :mybookings_resources, :name
  end
end
