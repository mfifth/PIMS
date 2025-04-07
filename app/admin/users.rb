ActiveAdmin.register User do
  permit_params :name, :email_address, :password, :phone

  index do
    column :name
    column :email_address
    column :password
    column :phone
    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :email_address
      f.input :password
      f.input :phone
    end
    f.actions
  end
end
