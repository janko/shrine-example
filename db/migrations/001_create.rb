Sequel.migration do
  change do
    create_table :albums do
      primary_key :id
      column :name, :varchar
    end

    create_table :photos do
      primary_key :id
      foreign_key :album_id, :albums
      column :image_data, :text
    end
  end
end
